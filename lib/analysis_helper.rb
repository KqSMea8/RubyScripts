require "analysis_helper/version"
require "analysis_helper/analysis_diff"
require "analysis_helper/analysis_filter"

module AnalysisHelper
  def AnalysisHelper.simple(log_file_path)
    log_repo_dir_path = "/Users/nami/git/TTStaticAnalyzeLog"
    analysis_tmp_file_path = log_repo_dir_path + "/NewsInHouse_analysis.tmp"
    warning_tmp_file_path = log_repo_dir_path + "/NewsInHouse_warning.tmp"

    puts("Filtering.")
    AnalysisHelper.filter(log_file_path, analysis_tmp_file_path, warning_tmp_file_path)
    puts("Analysis: #{analysis_tmp_file_path}, Waring: #{warning_tmp_file_path}")
    puts("Filter Success.")

    date_string = File.basename(log_file_path, '.*').delete_prefix("Analyze NewsInHouse_")

    analysis_file_path = log_repo_dir_path + "/NewsInHouse_analysis.txt"
    analysis_file_diffs_path = log_repo_dir_path + "/NewsInHouse_analysis_diffs_" + date_string + ".txt"
    puts("Diffing #{analysis_file_path} #{analysis_tmp_file_path}")
    AnalysisHelper.diff(analysis_file_path, analysis_tmp_file_path, analysis_file_diffs_path)
    puts("Diffs: #{analysis_file_diffs_path}")

    warning_file_path = log_repo_dir_path + "/NewsInHouse_warning.txt"
    warning_file_diffs_path = log_repo_dir_path + "/NewsInHouse_warning_diffs_" + date_string + ".txt"
    puts("Diffing #{warning_file_path} #{warning_file_diffs_path}")
    AnalysisHelper.diff(warning_file_path, warning_tmp_file_path, warning_file_diffs_path)
    puts("Diffs: #{warning_file_diffs_path}")
    puts("Diff success.")

    puts("Cleaning.")
    File.delete(analysis_file_path)
    File.rename(analysis_tmp_file_path, analysis_file_path)

    File.delete(warning_file_path)
    File.rename(warning_tmp_file_path, warning_file_path)
    puts("Clean success")
  end
end
