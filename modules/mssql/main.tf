/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


resource "google_sql_database_instance" "default" {
  project          = var.project_id
  name             = var.db_name
  database_version = var.database_version
  region           = var.region

  settings {
    tier = var.tier
    dynamic "backup_configuration" {
      for_each = [var.backup_configuration]
      content {
        binary_log_enabled = lookup(backup_configuration.value, "binary_log_enabled", null)
        enabled            = lookup(backup_configuration.value, "enabled", null)
        start_time         = lookup(backup_configuration.value, "start_time", null)
      }
    }
  }
}

resource "random_id" "user-password" {
  keepers = {
    name = google_sql_database_instance.default.name
  }

  byte_length = 8
  depends_on  = [google_sql_database_instance.default]
}

resource "google_sql_user" "default" {
  name       = var.user_name
  project    = var.project_id
  instance   = google_sql_database_instance.default.name
  password   = var.user_password == "" ? random_id.user-password.hex : var.user_password
  depends_on = [google_sql_database_instance.default]
}


resource "google_sql_user" "additional_users" {
  count   = length(var.additional_users)
  project = var.project_id
  name    = var.additional_users[count.index]["name"]
  password = lookup(
    var.additional_users[count.index],
    "password",
    random_id.user-password.hex,
  )
  instance   = google_sql_database_instance.default.name
  depends_on = [google_sql_database_instance.default]
}
