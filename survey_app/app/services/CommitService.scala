package services

import java.io.Serializable
import java.sql.Timestamp
import javax.inject.{Inject, Singleton}

import anorm.SqlParser.{bool, get, int, str}
import anorm.{RowParser, SQL, SqlParser, ~}
import org.joda.time.DateTime
import play.api.db.Database
import play.api.libs.json.{JsValue, Json}

case class CommitGuruCommitSummary(classification: String)
object CommitGuruCommitSummary {
  implicit val format = Json.format[CommitGuruCommitSummary]
}

case class SGCommitSummary(status: String, build_status: Option[String], processed: Option[DateTime],
                           warnings: Option[Int], new_warnings: Option[Int])
object SGCommitSummary {
  implicit val format = Json.format[SGCommitSummary]
}

case class Commit(repo: String, commit: String, author_name: String, commit_message: String, author_date: DateTime,
                  files_changed: JsValue,
                  commit_guru: CommitGuruCommitSummary, staticguru: SGCommitSummary)
object Commit {
  implicit val format = Json.format[Commit]
}

case class SimpleCommit(repo: String, name: String, commit: String, author_name: String, author_email: String,
                        commit_message: String, author_date: DateTime)
object SimpleCommit {
  implicit val format = Json.format[SimpleCommit]
}

case class CommitWithWarning(repo: String, name: String, commit: String, author_name: String, commit_message: String,
                             new_warnings: Int, email_created: Option[DateTime], email_sent: Option[DateTime],
                             author_date: DateTime)
object CommitWithWarning {
  implicit val format = Json.format[CommitWithWarning]
}

case class CommitWarning(id: Int, resource: String, line: Int, sfp: String, cwe: String, generator_tool: String,
                         weakness: String, origin_commit: String, origin_resource: String, origin_line: Int,
                         new_warning: Boolean)
object CommitWarning {
  implicit val format = Json.format[CommitWarning]
}

case class CommitFileWarning()

//File: {warnings: }


case class CommitBuildLog(log: String)
object CommitBuildLog {
  implicit val format = Json.format[CommitBuildLog]
}

@Singleton
class CommitService @Inject()(database: Database){
  val commitParser: RowParser[Commit] = {
    str("repository_id") ~ str("commit_hash") ~ str("author_name") ~ str("commit_message") ~
      str("author_date_unix_timestamp") ~ str("fileschanged") ~
      str("classification") ~
      (str("status")?) ~ (str("build")?) ~ (get[DateTime]("modified")?) ~ (int("static_warnings")?) ~ (int("new_static_warnings")?) map {
      case repo ~ commit ~ author_name ~ commit_message ~ author_date_unix_timestamp ~ files_changed ~
        classification ~
        status ~ build ~ modified ~ static_warnings ~ new_static_warnings   =>
        Commit(repo, commit, author_name, commit_message,  new DateTime(author_date_unix_timestamp.toLong*1000), Json.parse(files_changed),
          CommitGuruCommitSummary(classification),
          SGCommitSummary(status.getOrElse("NOT_ANALYSED"), build, modified, static_warnings, new_static_warnings))
    }
  }

  val simpleCommitParser: RowParser[SimpleCommit] = {
    str("repository_id") ~ str("name") ~ str("commit_hash") ~ str("author_name") ~ str("author_email") ~
      str("commit_message") ~ str("author_date_unix_timestamp") map {
      case repo ~ name ~ commit ~ author_name ~ author_email ~ commit_message ~ author_date_unix_timestamp  =>
        SimpleCommit(repo, name, commit, author_name, author_email, commit_message,
          new DateTime(author_date_unix_timestamp.toLong*1000))
    }
  }

  def toDate(date: Option[Timestamp]): Option[DateTime] = date match {
    case Some(string) =>
      Some(new DateTime(string))
    case _ =>
      None
  }


  val commitWithWarningParser: RowParser[CommitWithWarning] = {
    str("repo") ~ str("name") ~ str("commit") ~ str("author_name") ~ str("commit_message") ~
      str("author_date_unix_timestamp") ~ int("new_warnings") ~ (get[DateTime]("email_created")?) ~
      (get[DateTime]("email_sent")?) map {
      case repo ~ name ~ commit ~ author_name ~ commit_message ~ author_date_unix_timestamp ~ new_warnings ~
        email_created ~ email_sent  =>
        CommitWithWarning(repo, name, commit, author_name, commit_message, new_warnings, email_created,
          email_sent, new DateTime(author_date_unix_timestamp.toLong*1000))
    }
  }


  def getCommitByName(repo: String, commit: String): SimpleCommit = {
    database.withConnection { implicit c =>
      SQL(
        """
          |SELECT c.*, r.*
          |FROM COMMITS as c, REPOSITORIES as r
          |WHERE name = {repo} and commit_hash = {commit};
        """.stripMargin
      )
        .on('repo -> repo, 'commit -> commit)
        .as(simpleCommitParser.*).head
    }
  }

  def commits(repo: String, page: Int, limit: Int): List[Commit] = {
    database.withConnection { implicit c =>
      SQL(
        """
          |SELECT c.*, p.status, p.build, p.created, p.modified, w.warnings, w.new_warnings FROM COMMITS as c
          |
          |LEFT JOIN Static_commit_processed as p on (c.repository_id = p.repo and c.commit_hash = p.commit)
          |LEFT JOIN commit_warning_summary as w ON (w.repo = c.repository_id and w.commit = c.commit_hash)
          |
          |WHERE REPOSITORY_ID = {repo}
          |ORDER BY author_date_unix_timestamp DESC
          |LIMIT {limit}
          |OFFSET {offset};
        """.stripMargin
      )
        .on('repo -> repo, 'limit -> limit, 'offset -> (page - 1)*limit)
        .as(commitParser.*)
    }
  }

  def getCommitsWithWarnings(limit: Int, page: Int): List[CommitWithWarning] = {

    database.withConnection { implicit c =>
      SQL(
        """
          |select t.* from
          |
          |(select DISTINCT on (author_name, author_email) author_name, author_email, r.name,
          |w.repo, w.commit,
          | author_date_unix_timestamp,
          |new_warnings,
          |commit_message,
          |email_created, email_sent
          |from commit_warning_recovered_summary as w
          |join commits as c on (w.commit = c.commit_hash)
          |join repositories as r on (r.id = w.repo)
          |LEFT JOIN review_email_logging as e on (e.commit = w.commit)
          |where new_warnings > 0 and email_sent is null
          |and author_email not in (select author_email from review_unsubscribe)
          |order by author_name, author_email, author_date_unix_timestamp desc) as t
          |
          |where author_email not in (select author_email from review_email_logging as l
          |join commits as c on (c.commit_hash = l.commit)
          |where email_sent > NOW() - interval '7 day')
          |
          |order by author_date_unix_timestamp desc
          |
          |LIMIT {limit}
          |OFFSET {offset};
        """.stripMargin
      )
        .on('limit -> limit, 'offset -> page*limit)
        .as(commitWithWarningParser.*)
    }
  }

//  def getCommit(repo: String, commit:String): Commit
//

  val commitWarningParser: RowParser[CommitWarning] = {
    int("id") ~ str("resource") ~ int("line") ~ str("sfp") ~ str("cwe") ~
      str("generator_tool") ~ str("weakness") ~ str("origin_commit") ~ str("origin_resource") ~
      int("origin_line") ~ bool("is_new_line") map {
      case id ~ resource ~ line ~ sfp ~ cwe ~ generator_tool ~ weakness ~ origin_commit ~
        origin_resource ~ origin_line ~ new_warning =>
        // TODO remove splitting on resource when this is addressed in data
        CommitWarning(id, resource.substring(1), line, sfp, cwe, generator_tool, weakness, origin_commit,
          origin_resource.trim, origin_line, new_warning)
    }
  }


  def getCommitWarnings(repo: String, commit: String): List[CommitWarning] = {
  database.withConnection { implicit c =>
    SQL(
      """
        |Select w.*, b.origin_commit, b.origin_resource, b.origin_line, b.is_new_line
        |from static_commit_line_warning as w, static_commit_line_blame as b
        |where (w.repo, w.commit, w.resource, w.line) = (b.repo, b.commit, b.resource, b.line)
        |and w.repo = {repo} and w.commit = {commit}
      """.stripMargin
    )
      .on('repo -> repo, 'commit -> commit)
      .as(commitWarningParser.*)
  }
}




  case class CommitBuildLog(log: String)
  object CommitBuildLog {
    implicit val format = Json.format[CommitBuildLog]
  }

  def getCommitBuildLog(repo: String, commit: String): CommitBuildLog = {
    database.withConnection { implicit c =>
      val log = SQL(
        """
          |SELECT build_log FROM static_commit_processed WHERE repo = {repo} and commit = {commit}
        """.stripMargin
      )
        .on(
          'repo -> repo, 'commit -> commit)
        .as(SqlParser.str("build_log").
          single)
      CommitBuildLog(log)
    }
  }



  def getNewWarnings(repo:String, commit: String): List[CommitWarning] = {
    database.withConnection { implicit c =>
      SQL(
        """
        |select *
        | from static_commit_line_warning as w, static_commit_line_blame as b
        | where w.repo = b.repo and w.commit = b.commit and w.resource = b.resource and w.line = b.line
        | and b.is_new_line
        | and w.repo = {repo} and w.commit = {commit};
      """.
          stripMargin
    )
        .on('repo -> repo, 'commit -> commit)
      .as(commitWarningParser.*)

    }
  }

  def addReviewAccess(repo: String, commit: String, ip: String, accessType: String) = {
    database.withConnection{ implicit  c =>
      SQL(
        """
          |INSERT into static_commit_review_access(repo, commit, ip, type)
          |values ({repo}, {commit}, {ip}, {type})
        """.stripMargin
      ).on('repo -> repo, 'commit -> commit, 'ip -> ip, 'type -> accessType).execute()
    }

  }

  def addWarningReview(repo: String, commit: String, warning: Int, comment: String, useful: Boolean, ip: String) = {

    database.withConnection{ implicit  c =>
    SQL(
      """
        |INSERT into static_commit_line_warning_reviews(repo, commit, warning, comment, useful, ip)
        |values ({repo}, {commit}, {warning}, {comment}, {useful}, {ip})
      """.stripMargin
    )
      .on('repo -> repo, 'commit -> commit, 'warning -> warning, 'comment -> comment, 'useful -> useful, 'ip -> ip)
      .execute()
    }
  }

  def addUnsubscribe(repo: String, commit: String, author_email: String, ip: String) = {

    database.withConnection{ implicit  c =>
    SQL(
      """
        |INSERT into review_unsubscribe(repo, commit, author_email, ip)
        |values ({repo}, {commit}, {author_email}, {ip})
      """.stripMargin
    )
      .on('repo -> repo, 'commit -> commit, 'author_email -> author_email, 'ip -> ip)
      .execute()
    }
  }

  def emailCreatedLogging(repo: String, commit: String) = {
    database.withConnection{ implicit  c =>
      SQL(
        """
          |INSERT into review_email_logging(repo, commit, email_created)
          |values ({repo}, {commit}, NOW())
        """.stripMargin
      )
        .on('repo -> repo, 'commit -> commit)
        .execute()
    }

  }

  def emailSentLogging(repo: String, commit: String) = {
    database.withConnection{ implicit  c =>
      SQL(
        """
          |UPDATE review_email_logging SET email_sent = now()
          |where repo = {repo} and commit = {commit};
        """.stripMargin
      )
        .on('repo -> repo, 'commit -> commit)
        .execute()
    }

  }
}
