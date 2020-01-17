package services

import javax.inject.{Inject, Singleton}

import anorm.{RowParser, SQL, SqlParser}

import anorm._
import anorm.SqlParser._
import play.api.db.Database
import play.api.libs.json.Json

import scala.concurrent.Future

/**
  * Created by lquerel on 18/12/16.
  */


case class CommitGuru( status: String)
//case class CommitGuru(analysis_date: String, status: String)
object CommitGuru{
  implicit val format = Json.format[CommitGuru]
}

case class StaticBuild(success: Int, failure: Int, no_conf: Int, queued: Int, total: Int)
object StaticBuild{
  implicit val format = Json.format[StaticBuild]
}

case class Repo(id: String, name: String, commit_guru: CommitGuru, static_build: StaticBuild)
object Repo{
  implicit val format = Json.format[Repo]
}


@Singleton
class ReposService @Inject()(database: Database){


  val repoParser: RowParser[Repo] = {
    str("id") ~ str("name") ~ str("status") ~
    //str("id") ~ str("name") ~ str("analysis_date") ~ str("status") ~
      int("build_success") ~ int("build_failure") ~ int("build_no_conf") ~
      int("build_queued") ~ int("build_total") map {
        case id ~ name ~ status ~ success ~ failure ~ no_conf ~ queued ~ total =>
        //case id ~ name ~ analysis_date ~ status ~ success ~ failure ~ no_conf ~ queued ~ total =>
          Repo(id, name, CommitGuru(status), StaticBuild(success, failure, no_conf, queued, total))
    }
  }


  def repo: List[Repo] = {
    database.withConnection { implicit c =>
      SQL(
        """
          select * from repositories as r, (
          select repo,
           count(*) filter (where build='BUILD') as build_success,
           count(*) filter (where build='FAILURE') as build_failure,
           count(*) filter (where build='MISSING POM') as build_no_conf,
           count(*) filter (where build is NULL) as build_queued,
           count(*) as build_total
          from static_commit_processed group by repo
          ) as sg where r.id = sg.repo;
        """
      ).as(repoParser.*)
    }
  }
}
