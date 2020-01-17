package services

import javax.inject.Inject

import com.google.common.io.BaseEncoding
import play.api.Configuration
import play.api.cache.CacheApi
import play.api.libs.json.Json
import play.api.libs.ws.WSAuthScheme.BASIC
import play.api.libs.ws.WSClient
import sun.misc.BASE64Decoder

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{Await, Future}
import scala.concurrent.duration._


case class Line(number: Int, warning: Boolean, content: String)
object Line {
  implicit val format = Json.format[Line]
}


/**
  * Created by lquerel on 06/03/17.
  */
class GitHubService @Inject() (ws: WSClient, configuration: Configuration, cache: CacheApi) {

  val offset = 3 // lines
  def getFileSnippet(projectName: String, commit: String, filePath: String, line: Int) = {

    val file = getFile(projectName, commit, filePath)

    val fileLines = file.split("\n")
    val fileLinesLength = fileLines.length

    val min = if (line - offset > 0) line - offset else 1
    val max = if (line + offset < fileLinesLength) line + offset else fileLinesLength

    val targetLines = fileLines.slice(min-1, max)

    var lineNumber = min
    targetLines.map{ lineContent =>
      val currentLine = Line(lineNumber, lineNumber==line, lineContent)
      lineNumber += 1
      currentLine
    }

  }

  def getFile(projectName: String, commit: String, filePath: String) = {

    cache.getOrElse[String](s"$projectName$commit$filePath") {
      Await.result(getFileGithub(projectName, commit, filePath), 10 seconds)
    }

  }

  def getFileGithub(projectName: String, commit: String, filePath: String) = {
    val username = configuration.getString("github.username").get
    val password = configuration.getString("github.password").get

    ws.url(s"https://api.github.com/repos/apache/$projectName/contents/$filePath?ref=$commit")
      .withAuth(username, password, BASIC)
      .get().flatMap {response =>
      val file = (response.json \ "download_url").as[String]

      ws.url(file)
        .withAuth(username, password, BASIC)
        .get().map(_.body)

      }
    }
}
