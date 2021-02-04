#!/python3

'''Compiles all the .vso.hlsl and .pso.hlsl filenames in this directory and all subdirectories
'''

from multiprocessing import Pool
import os
from pathlib import Path
import subprocess
import time


fxc = r"C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Utilities\bin\x86\fxc.exe"


def compile_shader(shader, profile):

    print(f'Beginning compile of {shader}')
    start = time.process_time()

    output_file_name = shader[:-5]
    log_file_name = shader.replace('.hlsl', '.log')

    result = subprocess.run([fxc, '/T', profile, '/Fo', output_file_name, shader], shell = True, capture_output = True)
    if result.returncode != 0:
        with open(log_file_name, 'w') as log_file:
            if result.stdout is not None:
                log_file.write('stdout:')
                log_file.write(result.stdout)

            if result.stderr is not None:
                log_file.write('stderr:')
                log_file.write(str(result.stderr))

        print(f'Failed to compile {shader}! Check file {log_file_name} for details')

    else:
        end = time.process_time()
        print(f'Compiled {shader} in {end - start} seconds')


def compile_all_shaders_in_folder(folder):
    pool = Pool()

    for dirpath, dirnames, filenames in os.walk(folder):
        all_shaders = list()

        for shader_file in filenames:
            if shader_file.endswith('.fx.hlsl'):
                print(f'Compiling {shader_file} as an effect')
                all_shaders.append((f'{dirpath}/{shader_file}', 'fx_2_0'))

            if shader_file.endswith('.vso.hlsl'):
                print(f'Compiling {shader_file} as a vertex shader')
                all_shaders.append((f'{dirpath}/{shader_file}', 'vs_3_0'))

            elif shader_file.endswith('.pso.hlsl'):
                print(f'Compiling {shader_file} as a pixel shader')
                all_shaders.append((f'{dirpath}/{shader_file}', 'ps_3_0'))
    
        if len(all_shaders) > 0:
            pool.starmap_async(compile_shader, all_shaders)

        for dir in dirnames:
            compile_all_shaders_in_folder(dir)
    
    pool.close()


if __name__ == '__main__':
    compile_all_shaders_in_folder(os.curdir)
