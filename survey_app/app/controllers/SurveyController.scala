package controllers

import javax.inject.Inject

import org.joda.time.DateTime
import play.api.libs.json.{JsValue, Json}
import play.api.mvc.{Action, Controller}
import services._

import scala.concurrent.ExecutionContext.Implicits.global

/**
  * Created by lquerel on 02/03/17.
  */
case class SurveyWarning(warning: CommitWarning, lines: Array[Line])
object SurveyWarning {
  implicit val format = Json.format[SurveyWarning]
}


case class Survey(commit: SimpleCommit, warnings: List[SurveyWarning])
object Survey {
  implicit val format = Json.format[Survey]
}

case class ReviewCommit(repo: String, commit: String, author: String, date: String, new_warnings: Int,
                        review_url: String, email_url: String, email_sent: String)
object ReviewCommit {
  implicit val format = Json.format[ReviewCommit]
}

class SurveyController @Inject() (gh: GitHubService, reposService: ReposService, commitService: CommitService) extends Controller {
  val base = "http://paolini.encs.concordia.ca:9000"


  def getSurveyAddress(commit: CommitWithWarning): String = getSurveyAddress(commit.name, commit.commit, commit.author_date)
  def getSurveyAddress(commit: SimpleCommit): String = getSurveyAddress(commit.name, commit.commit, commit.author_date)
  def getSurveyAddress(project: String, commit: String, date: DateTime) = s"$base/review/$project/$commit/${date.getMillis}"

  def getGitHubCommitUrl(project: String, commit: String) = s"https://github.com/apache/$project/commit/$commit"

  def getUnsubscribeAddress(project: String, commit: String) = s"$base/unsubscribe/$project/$commit"

  def getCommitsWithWarnings = Action {

    val possible_commits = commitService.getCommitsWithWarnings(100, 0)
      .map{ commit =>


      ReviewCommit(commit.name, commit.commit, commit.author_name, commit.author_date.toString, commit.new_warnings,
        getSurveyAddress(commit),
        s"$base/api/admin/review/message/${commit.name}/${commit.commit}",
        s"$base/api/admin/review/message/${commit.name}/${commit.commit}/sent")

    }

    Ok(Json.toJson(possible_commits))

  }

  def generateSurvey(projectName: String, commitHash: String) = Action {
    val commit = commitService.getCommitByName(projectName, commitHash)
    val warnings = commitService.getNewWarnings(commit.repo, commitHash)

    val warnings_count_message = if (warnings.length > 1) s" and the ${warnings.length-1} other${if (warnings.length > 2) "s " else " " }" else " "

    // subject: Question regarding ${projectName.capitalize} commit
    val email =
      s"""
        |email: ${commit.author_email}
        |subject: New FindBugs/JLint warning${if (warnings.length > 1) "s" else ""} on commit ${commitHash.substring(0,8)} of ${projectName.capitalize}
        |
        |
        |Dear ${commit.author_name},
        |
        |We are presently doing a study at Concordia University on the introduction of static analysis warnings (Findbugs & Jlint) in the commits of projects such as ${projectName.capitalize}. We have identified ${warnings.length} new possible warning${if (warnings.length > 1) "s" else ""} on the commit ${getGitHubCommitUrl(projectName, commitHash)} which you worked on ${commit.author_date}. An example follows below:
        |
        |file: ${warnings.head.resource}
        |warning: ${warnings.head.weakness}
        |line: ${warnings.head.line}
        |
        |We would appreciate it if you could indicate to us if this warning${warnings_count_message}are useful to you by either responding to this message or by going to the link below.
        |${getSurveyAddress(commit)}
        |
        |Thank you for your assistance,
        |
        |Best regards,
        |
        |Louis-Philippe Querel
        |
        |Master student in software engineering
        |Concordia University, Montreal, Quebec
        |l_querel@encs.concordia.ca
        |
        |To unsubscribe the email '${commit.author_email}' from please click on this link: ${getUnsubscribeAddress(projectName, commitHash)}
      """.stripMargin

    commitService.emailCreatedLogging(commit.repo, commitHash)
    Ok(email)
  }

  def emailSent(projectName: String, commitHash: String) = Action{
    val commit = commitService.getCommitByName(projectName, commitHash)
    commitService.emailSentLogging(commit.repo, commitHash)
    NoContent
  }

  def getSurvey(project_name: String, commit_hash: String, key: Long) = Action { request =>

    val commit = commitService.getCommitByName(project_name, commit_hash)

    if (key != commit.author_date.getMillis){
      Forbidden("You are not allowed to access this commit")
    } else {

      commitService.addReviewAccess(commit.repo, commit_hash, request.remoteAddress, "DATA")

      val warnings = commitService.getNewWarnings(commit.repo, commit_hash)

      val augmentedWarnings = warnings.map { warning =>
        val line_content = gh.getFileSnippet(project_name, commit_hash, warning.resource, warning.line)
        SurveyWarning(warning, line_content)
      }

      Ok(Json.toJson(Survey(commit, augmentedWarnings)))
    }
  }

  def saveSurvey(repoId: String, commit: String, warning: Int): Action[JsValue] = Action(parse.json) { request =>

    val comment = (request.body \ "comment").as[String]
    val useful = (request.body \ "useful").as[Boolean]

    commitService.addWarningReview(repoId, commit, warning, comment, useful, request.remoteAddress)

    NoContent

  }

  def unsubscribe(projectName: String, commitHash: String) = Action { request =>

    commitService.getCommitByName(projectName, commitHash) match {
      case commit: SimpleCommit =>
        commitService.addUnsubscribe(commit.repo, commitHash, commit.author_email, request.remoteAddress)

        Ok(
          s"""
             |<html><head><title>Unsubscribe from emails for study on '$projectName'</title></head>
             |<body>
             |<h4>Sorry about disturbing you</h4>
             | Your email address will no longer receive correspondence regarding our study on ${projectName.capitalize}.
             | <br /><br />
             | If you have any questions you can reach me at l_querel@encs.concordia.ca
             |  <br /><br />
             |  Best regards,
             |  <br /><br />
             |  Louis-Philippe Querel
             |  </body>
             |  </html>
      """.stripMargin).withHeaders("content-type" -> "text/html")

      case _ => NotFound("Sorry, we can't seem to find you. If you receive other emails get in touch with l_querel@encs.concordia.ca to resolve this")

    }



  }

}
