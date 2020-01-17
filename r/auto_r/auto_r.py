"""
auto_r.py

This script is my attempt to automate the whole r process so that I don't need to create seperate files for each
projects. Instead it get's the list of repositories from the database and automatically generates an R file for them
based on a set of templates. These templates are then run automatically and we should obtain all the data that we want

Author: Louis-Philippe Querel
"""
import os

from postgres import Postgres
from datetime import datetime

TEMPLATES_DIR = "templates"
GENERATED_DIR = "auto_generated"
IMAGES_DIR = "../figures"
SUMMARY_DIR = "../summaries"

GENERATOR_TITLE = "######\n#Auto-generated file (%s) using auto_r.py. Do not modify manually\n######\n\n" % str(
    datetime.now())


def main():
    repositories = _extract_repositories()
    template_files = _load_template_files()

    generated_path = os.path.join(os.path.curdir, GENERATED_DIR)
    image_path = os.path.abspath(os.path.join(os.path.curdir, IMAGES_DIR))
    summary_path = os.path.abspath(os.path.join(os.path.curdir, SUMMARY_DIR))

    # _generate_summary()

    for repository in repositories:
        repository_id = repository[0]
        repository_name = repository[1]

        for template_file in filter(lambda template: "ALL" not in template, template_files.keys()):

            _generate_and_run_r(generated_path, template_files, template_file, repository_name, repository_name, repository_id, image_path, summary_path)

    for template_file in filter(lambda template: "ALL" in template, template_files.keys()):

        _generate_and_run_r(generated_path, template_files, template_file, template_file, template_file, template_file, image_path, summary_path)


def _generate_and_run_r(generated_path, template_files, template_file, title, repository_name, repository_id, image_path, summary_path):
    # Generate file content based on template file
    generated_file = template_files[template_file].format(title=title,
                                                          repository=repository_name,
                                                          repository_id=repository_id,
                                                          image_path=image_path,
                                                          summary_path=summary_path)

    # Save generated file
    file_path = os.path.join(generated_path, "%s_%s" % (title, template_file))
    with open(file_path, 'w') as f:
        f.write(GENERATOR_TITLE + generated_file)
        f.close()

    # Run R on this newly generated file

    os.system("R < %s --no-save" % file_path)

# def _extract_repositories():
#     db = Postgres().getCursor()
#     db.execute("""SELECT distinct repo FROM static_commit_processed WHERE build = 'BUILD';""")
#     return db.fetchall()

def _extract_repositories():
    db = Postgres().getCursor()
    db.execute("""select id, name from repositories where id in (SELECT distinct repo FROM static_commit_processed WHERE build = 'BUILD');""")
    return db.fetchall()


def _generate_summary():
    with open('summary.sql', 'r') as f:
        sql = f.read()

    db = Postgres().getCursor()
    db.execute(sql)


def _load_template_files():
    templates = {}

    template_directory = os.path.join(os.path.curdir, TEMPLATES_DIR)
    for template in os.listdir(template_directory):
        with open(os.path.join(template_directory, template)) as f:
            templates[template] = (f.read())

    return templates


if __name__ == "__main__":
    main()
