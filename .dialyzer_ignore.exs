should_fix = [
  {"lib/astrox/bulk.ex", :no_return},
  {"lib/mix/tasks/compile.astrox.ex", :callback_info_missing},
]

known_bug = [
]

dependency_issue = [
]

should_fix ++ known_bug ++ dependency_issue
