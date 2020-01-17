package controllers

import javax.inject.Inject

import play.api._
import play.api.mvc._
import services.{CommitService, GitHubService, ReposService}

class Application @Inject() (reposService: ReposService, commitService: CommitService) extends Controller  {

  def index = Action { request =>

    val path = request.path.split("/")
    /** change the template here to use a different way of compilation and loading of the ts ng2 app.
      * index()  :    does no ts compilation in advance. the ts files are download by the browser and compiled there to js.
      * index1() :    compiles the ts files to individual js files. Systemjs loads the individual files.
      * index2() :    add the option -DtsCompileMode=stage to your sbt task . F.i. 'sbt ~run -DtsCompileMode=stage' this will produce the app as one single js file.
      */
    val repo = path(path.length-2)
    val commit_hash = path(path.length-1)
    commitService.addReviewAccess(repo, commit_hash, request.remoteAddress, "INDEX")
    Ok(views.html.index1())
  }

  def notFound(notFound: String) = Default.notFound

  def other(others: String) = index
}
