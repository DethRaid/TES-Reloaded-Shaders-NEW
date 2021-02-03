#!/python3

'''Compiles all the .vso.hlsl and .pso.hlsl files in this directory and all subdirectories
'''

import os
from pathlib import Path
import subprocess


fxc = r"C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Utilities\bin\x86\fxc.exe"


def compile_effect(effect, parent_directory):
    print(f"Compiling effect {parent_directory}/{effect}")


def compile_shader(shader, profile):
    print(f"Compiling shader {shader}")

    output_file = shader[:-5]

    result = subprocess.run([fxc, '/T', profile, '/Fo', output_file, shader], shell = True, capture_output = True, text = True)
    if result.returncode != 0:
        log_file_name = shader.replace('.hlsl', '.log')
        with open(log_file_name, 'w') as log_file:
            if result.stdout is not None:
                log_file.write('stdout:')
                log_file.write(result.stdout)

            if result.stderr is not None:
                log_file.write('stderr:')
                log_file.write(str(result.stderr))

        print(f"Errors when compiling shader! Check file {log_file_name} for details")

    else:
        print('Compilation successful!')


def compile_all_shaders_in_folder(folder):
    for subdir, dirs, files in os.walk(folder):
        for shader_file in files:
            if shader_file.endswith('.fx.hlsl'):
               compile_shader(f"{subdir}/{shader_file}", "fx_2_0")
            
            elif shader_file.endswith('.vso.hlsl'):
                compile_shader(f"{subdir}/{shader_file}", 'vs_3_0')

            elif shader_file.endswith('.pso.hlsl'):
                compile_shader(f"{subdir}/{shader_file}", 'ps_3_0')
        
        for dir in dirs:
            compile_all_shaders_in_folder(dir)


if __name__ == '__main__':
    compile_all_shaders_in_folder(os.curdir)
