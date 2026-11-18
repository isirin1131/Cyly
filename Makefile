# 对 meson 的简单封装。直接运行 `make help` 查看所有命令。

BUILD_DIR ?= build
BUILD_TYPE ?= debug
TYPST ?= typst
TYPST_FLAGS ?=
SPEC_PDF := output/pdf/cyly-language-spec.pdf

.DEFAULT_GOAL := build
.PHONY: help build test run setup reconfigure release clean docs

help: ## 显示所有命令
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-12s %s\n", $$1, $$2}'

# build 目录不存在时自动执行 meson setup
$(BUILD_DIR)/build.ninja:
	meson setup $(BUILD_DIR) --buildtype=$(BUILD_TYPE)

setup: $(BUILD_DIR)/build.ninja ## 初始化构建目录（一般不用手动执行）

build: $(BUILD_DIR)/build.ninja ## 编译（默认目标）
	meson compile -C $(BUILD_DIR)

test: $(BUILD_DIR)/build.ninja ## 编译并运行全部测试
	meson test -C $(BUILD_DIR) --print-errorlogs

docs: ## 用 Typst 渲染语言规范 PDF（需要中文字体）
	mkdir -p output/pdf
	$(TYPST) compile $(TYPST_FLAGS) docs/language-spec.typ $(SPEC_PDF)

run: build ## 运行 cyly（make run FILE=path/to/source.cy）
	@test -n "$(FILE)" || { echo "Usage: make run FILE=path/to/source.cy" >&2; exit 2; }
	./$(BUILD_DIR)/cyly "$(FILE)"

reconfigure: ## 修改 meson.build 后若出问题，强制重新配置
	meson setup --reconfigure $(BUILD_DIR) --buildtype=$(BUILD_TYPE)

release: ## 用 release 模式重新构建
	rm -rf $(BUILD_DIR)
	$(MAKE) build BUILD_TYPE=release

clean: ## 删除整个构建目录
	rm -rf $(BUILD_DIR)
