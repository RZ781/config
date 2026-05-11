if !has("python3")
	finish
endif

py3 << END
import os, tempfile, re, subprocess

class Intellisense:
	errors = {} # dict[buffer -> dict[line -> list[errors]]]
	func = None

	c_error_regex = re.compile("^([^:]+):([0-9]+):[0-9]+: ([^:]+): (.*)\\n")
	@staticmethod
	def get_c_errors(code_path, real_path):
		folder = real_path
		include = ""
		for i in range(5):
			folder = os.path.dirname(folder)
			folders = os.listdir(folder)
			if "include" in folders:
				include = f"-I {folder}/include"
				break
		p = subprocess.Popen(f"gcc -Wall -Wextra -Wpedantic -c {code_path[1]} {include} -o /dev/null", shell=True, stderr=subprocess.PIPE, text=True)
		while p.poll() is None:
			yield
		errors = {}
		for line in p.stderr:
			match = Intellisense.c_error_regex.fullmatch(line)
			if not match:
				continue
			file_name = match.group(1)
			line_num = int(match.group(2))
			error_type = match.group(3)
			error = match.group(4)
			if file_name == code_path[1] and error_type != "note":
				if line_num in errors:
					errors[line_num].append(error)
				else:
					errors[line_num] = [error]
		return errors

	@staticmethod
	def update_errors():
		error_gens = {
			b"c": Intellisense.get_c_errors,
			b"cpp": Intellisense.get_c_errors,
		}
		for buf in vim.buffers:
			if buf.options["filetype"] not in error_gens:
				continue
			code_path = tempfile.mkstemp(suffix=f".{buf.options['filetype'].decode('utf8')}", text=True)
			with open(code_path[0], "w") as f:
				f.write("\n".join(buf))
			for ft in error_gens:
				if buf.options["filetype"] == ft:
					Intellisense.errors[buf.name] = yield from error_gens[ft](code_path, buf.name)
					break
			os.remove(code_path[1])
		Intellisense.display_errors()

	remove_errors_regex = re.compile("\\s?// ERROR:.*")
	@staticmethod
	def display_errors():
		saved_poses = []
		for win in vim.windows:
			saved_poses.append((win, win.cursor))
		buf_map = {}
		for buf in vim.buffers:
			buf_map[buf.name] = buf
		delete_errors = []
		for buf_name, errors in Intellisense.errors.items():
			if buf_name not in buf_map:
				delete_errors.append(buf_name)
			buf = buf_map[buf_name]
			for i, line in enumerate(buf):
				new_line = Intellisense.remove_errors_regex.sub("", line)
				if line != new_line:
					buf[i] = new_line
			for line, error in errors.items():
				if line > len(buf):
					line = len(buf)
				buf[line-1] = buf[line-1] + f" // ERROR: {', '.join(error[:3])}"
		for buf_name in delete_errors:
			del Intellisense.errors[buf_name]
		for win, win_cursor in saved_poses:
			win.cursor = win_cursor

	@staticmethod
	def tick():
		if Intellisense.func is None:
			Intellisense.func = Intellisense.update_errors()
		try:
			next(Intellisense.func)
		except StopIteration:
			Intellisense.func = None
END

function s:Update(timer_id)
	py3 Intellisense.tick()
endfunction

function Intellisense()
	call timer_start(100, function("s:Update"), #{repeat: -1})
	autocmd BufRead,BufNewFile * syntax match Error "// ERROR:.*"
	syntax match Error "// ERROR:.*"
endfunction
