pid_file = "./pidfile"
exit_after_auth = true

vault {
#  address = "https://vault.example.com" # set by env var
  retry {
    num_retries = -1
  }
}


auto_auth {
  method "jwt" {
    config = {
      role = "appname-deploy"
      path = ".circleci/vault/token.json"
      remove_jwt_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}



template {
  source      = ".circleci/vault/cluster.ctmpl"
  destination = ".circleci/vault/setenv"
}