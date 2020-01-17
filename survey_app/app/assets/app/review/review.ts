// import {RepoBuild} from './repo-build';
export class Review {
  public commit: Commit;
  public warnings: Warning[];
}

export class Commit {
  public repo: String;
  public name: String;
  public commit: String;
  public author_name: String;
  public commit_message: String;
  public author_date: number;
}

export class Warning {
  public warning: DetailedWarning;
  public lines: Line[];

}

export class DetailedWarning {
  public id: number;
  public resource: String;
  public line: number;
  public sfp: String;
  public cwe: String;
  public generator_tool: String;
}

export class Line {
  public number: number;
  public warning: boolean;
  public content: String;

}
