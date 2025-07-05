# 这里对应的是 ".gitlab-ci.yml"文件中的 test.script: - make test
test:
	go test ./...

# 这里对应的是 ".gitlab-ci.yml"文件中的 compile.script: - make build
build:
	go build \
	  -race \
	  -ldflags "-X git.aaron.com/${CI_PROJECT_PATH}/vendor/github.com/prometheus/common/version.Version=$(shell cat VERSION) \
	  -X git.aaron.com/${CI_PROJECT_PATH}/vendor/github.com/prometheus/common/version.Revision=${CI_COMMIT_SHA} \
	  -X git.aaron.com/${CI_PROJECT_PATH}/vendor/github.com/prometheus/common/version.Branch=${CI_COMMIT_REF_NAME} \
	  -X git.aaron.com/${CI_PROJECT_PATH}/vendor/github.com/prometheus/common/version.BuildUser=$(shell whoami)@$(shell hostname) \
	  -X git.aaron.com/${CI_PROJECT_PATH}/vendor/github.com/prometheus/common/version.BuildDate=$(shell date +%Y%m%d-%H:%M:%S) \
	  -extldflags '-static'" \
	  -o app

.PHONY: test build
