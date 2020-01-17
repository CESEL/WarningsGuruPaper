package controllers

import javax.inject.Inject

import play.api.libs.json._
import play.api.mvc.{Action, Controller}
import services.{CommitService, CommitWarning, HeroesService, ReposService}

import scala.collection.mutable.ListBuffer
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

/**
  * Created by lquerel on 18/12/16.
  */



class Repo @Inject()(reposService: ReposService, commitService: CommitService) extends Controller {
  def all = Action {
    //heroesService.all.map { s => Ok(toDataField(s)) }

    Ok(toDataField(reposService.repo))
    //    Ok(Json.toJson(reposService.repo))
  }

  def commits(repoId: String) = Action.async { request =>
    Future {
      val page = request.getQueryString("page").getOrElse("1").toInt
      val limit = request.getQueryString("limit").getOrElse("25").toInt

      val commits = commitService.commits(repoId, page, limit)
      Ok(JsObject(Seq("data" -> Json.toJson(commits), "pagination" -> JsObject(Seq("page" -> JsNumber(page), "limit" -> JsNumber(limit))))))
    }
  }

  def commitWarnings(repoId: String, commit: String) = Action.async {
    Future {
      var sortedCommitWarnings: Map[String, ListBuffer[CommitWarning]] = Map()

      commitService.getCommitWarnings(repoId, commit).foreach { commitWarning =>
        val resource = commitWarning.resource

        if (sortedCommitWarnings.contains(resource)){
          sortedCommitWarnings(resource) += commitWarning
        } else {
          sortedCommitWarnings += (resource -> ListBuffer(commitWarning))
        }
      }
      Ok(toDataField(sortedCommitWarnings))
    }
  }

  def commitBuildLog(repoId: String, commit: String) = Action.async {
    Future {
      Ok(toDataField(commitService.getCommitBuildLog(repoId, commit)))
    }
  }

  private def toDataField[A](value: A)(implicit writes: Writes[A]): JsValue = {
    JsObject(Seq("data" -> Json.toJson(value)))
  }
}
