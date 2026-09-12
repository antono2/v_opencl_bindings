#!/usr/bin/env -S v run

// Installs and verifies the native prerequisites used by antono2.opencl.
// Running without arguments performs the installation. Use --check for a
// read-only diagnostic pass suitable for support requests and CI.

import os

const usage = 'Usage: v run setup.vsh [--install|--check]\n\n' + '  --install  Install the OpenCL loader, headers, a development runtime, and this V module (default).\n' + '  --check    Only report whether the compiler, headers, loader, and an OpenCL platform work.\n'

fn command_exists(name string) bool {
	os.find_abs_path_of_executable(name) or { return false }
	return true
}

fn run(command string) ! {
	println('\n> ${command}')
	result := os.execute(command)
	if result.output.trim_space() != '' {
		println(result.output.trim_right('\r\n'))
	}
	if result.exit_code != 0 {
		return error('command failed with exit code ${result.exit_code}')
	}
}

fn install_linux() ! {
	if command_exists('apt-get') {
		run('sudo apt-get update')!
		run('sudo apt-get install -y build-essential clinfo ocl-icd-opencl-dev pocl-opencl-icd')!
		return
	}
	if command_exists('dnf') {
		run('sudo dnf install -y gcc gcc-c++ clinfo ocl-icd-devel opencl-headers pocl')!
		return
	}
	if command_exists('pacman') {
		run('sudo pacman -S --needed --noconfirm base-devel clinfo ocl-icd opencl-headers pocl')!
		return
	}
	if command_exists('zypper') {
		run('sudo zypper --non-interactive install -y gcc gcc-c++ clinfo ocl-icd-devel opencl-headers pocl')!
		return
	}
	return error('unsupported Linux package manager; install OpenCL headers, an ICD loader, clinfo, and an ICD such as PoCL, then rerun with --check')
}

fn install_macos() ! {
	if !command_exists('xcode-select') || os.execute('xcode-select -p').exit_code != 0 {
		return error('Apple Command Line Tools are required; run `xcode-select --install`, then retry')
	}
	println('The OpenCL headers, loader, and implementation are provided by the macOS OpenCL framework.')
}

fn install_windows() ! {
	if !command_exists('winget') {
		return error('winget is required for automatic Windows setup; install Microsoft App Installer, then try again')
	}
	if !command_exists('git') {
		run('winget install --id Git.Git --exact --accept-package-agreements --accept-source-agreements')!
	}
	if !command_exists('cmake') {
		run('winget install --id Kitware.CMake --exact --accept-package-agreements --accept-source-agreements')!
	}
	path_result := os.execute('powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable(\'Path\',\'Machine\') + \';\' + [Environment]::GetEnvironmentVariable(\'Path\',\'User\')"')
	if path_result.exit_code == 0 && path_result.output.trim_space() != '' {
		os.setenv('PATH', path_result.output.trim_space(), true)
	}
	cache_root := os.join_path(os.cache_dir(), 'antono2', 'opencl')
	vcpkg_root := os.join_path(cache_root, 'vcpkg')
	if !os.is_dir(vcpkg_root) {
		os.mkdir_all(cache_root)!
		run('git clone --depth 1 https://github.com/microsoft/vcpkg.git ${os.quoted_path(vcpkg_root)}')!
	}
	bootstrap := os.join_path(vcpkg_root, 'bootstrap-vcpkg.bat')
	vcpkg := os.join_path(vcpkg_root, 'vcpkg.exe')
	if !os.is_file(vcpkg) {
		run(os.quoted_path(bootstrap))!
	}
	run('${os.quoted_path(vcpkg)} install opencl:x64-windows')!
	sdk_root := os.join_path(vcpkg_root, 'installed', 'x64-windows')
	module_root := os.dir(os.real_path(@FILE))
	os.mkdir_all(os.join_path(module_root, 'lib'))!
	os.cp(os.join_path(sdk_root, 'lib', 'OpenCL.lib'), os.join_path(module_root, 'lib', 'OpenCL.lib'))!
	os.setenv('OPENCL_SDK', sdk_root, true)
	// Persist the development location for new terminals. The current process
	// is also updated above so verification can continue without a restart.
	run('setx OPENCL_SDK ${os.quoted_path(sdk_root)}')!
	println('\nThe Khronos loader is installed for development. Install the current GPU vendor driver to provide an OpenCL implementation.')
}

fn install_native() ! {
	$if linux {
		install_linux()!
	} $else $if macos {
		install_macos()!
	} $else $if windows {
		install_windows()!
	} $else {
		return error('automatic setup is not supported on this operating system')
	}
}

fn find_opencl_header() string {
	mut roots := []string{}
	if sdk := os.getenv_opt('OPENCL_SDK') {
		roots << sdk
	}
	$if macos {
		framework := '/System/Library/Frameworks/OpenCL.framework'
		if os.is_dir(framework) {
			return framework
		}
	} $else $if !windows {
		roots << ['/usr', '/usr/local', '/opt/homebrew']
	}
	for root in roots {
		for relative in ['include/CL/opencl.h', 'Headers/opencl.h'] {
			candidate := os.join_path(root, relative)
			if os.is_file(candidate) {
				return candidate
			}
		}
	}
	return ''
}

fn report_command(name string, required bool) bool {
	if path := os.find_abs_path_of_executable(name) {
		println('[ok]       ${name}: ${path}')
		return true
	}
	label := if required { 'missing' } else { 'optional' }
	println('[${label}] ${name}')
	return !required
}

fn check() bool {
	println('\nOpenCL setup check')
	println('------------------')
	mut ok := true
	ok = report_command('v', true) && ok
	$if windows {
		report_command('cl', false)
	} $else {
		ok = report_command('cc', true) && ok
	}
	header := find_opencl_header()
	$if macos {
		if header == '' {
			println('[missing] macOS OpenCL framework headers')
			ok = false
		} else {
			println('[ok]       OpenCL framework header: ${header}')
		}
	} $else {
		if header == '' {
			println('[missing] OpenCL development headers')
			ok = false
		} else {
			println('[ok]       OpenCL header: ${header}')
		}
	}
	if command_exists('clinfo') {
		result := os.execute('clinfo -l')
		if result.exit_code == 0 && result.output.contains('Platform') {
			println('[ok]       OpenCL loader enumerated a platform')
		} else {
			println('[warning]  the loader is installed, but no OpenCL platform was found')
			println('           Install the GPU vendor driver or a CPU implementation such as PoCL.')
		}
	} else {
		$if windows {
			if os.exists(os.join_path(os.getenv('WINDIR'), 'System32', 'OpenCL.dll')) {
				println('[ok]       OpenCL.dll is installed')
			} else {
				println('[warning]  OpenCL.dll was not found; install the current GPU vendor driver')
			}
		} $else $if macos {
			println('[ok]       macOS OpenCL framework is available')
		} $else {
			println('[warning]  clinfo is unavailable; OpenCL runtime verification was skipped')
		}
	}
	return ok
}

fn main() {
	if os.args.len > 2 || (os.args.len == 2 && os.args[1] !in ['--install', '--check', '-h', '--help']) {
		eprintln(usage)
		exit(2)
	}
	if os.args.len == 2 && os.args[1] in ['-h', '--help'] {
		println(usage)
		return
	}
	install := os.args.len == 1 || os.args[1] == '--install'
	if install {
		install_native() or {
			eprintln('Setup failed: ${err}')
			exit(1)
		}
		if command_exists('v') {
			run('v install antono2.opencl') or {
				eprintln('Could not install the V module: ${err}')
				exit(1)
			}
		}
	}
	if !check() {
		eprintln('\nSetup is incomplete. Resolve the missing items above and rerun with --check.')
		exit(1)
	}
	println('\nOpenCL development prerequisites are ready.')
}
