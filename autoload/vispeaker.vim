
let s:using_python3 = 0

let s:script_folder_path = escape( expand( '<sfile>:p:h' ), '\' )

let s:vis_server_start = 0
let s:vis_client_start = 0
let s:record_job_created = 0
let s:python_until_eof = "python << EOF"
let s:python_command = "py"

function! s:Pyeval( eval_string )
  if s:using_python3
    return py3eval( a:eval_string )
  endif
  return pyeval( a:eval_string )
endfunction


function! s:SetUpServerAndClient()
  exec s:python_until_eof
from __future__ import print_function
import os
import sys
import vim

# Add python source folder to the system path.
script_folder = vim.eval( 's:script_folder_path' )
sys.path.insert( 0, os.path.join(script_folder, '..', 'python') )

from vis import vis_client
vis_client = vis_client.VIspeaker()
vis_client.trap_sigint()
vim.command( 'let s:vis_client_start = 1' )
EOF
let s:vis_server_start = 1 " TODO
endfunction

function! s:CreateRecordJobIfNeed()
  if s:record_job_created
    return
  endif

  exec s:python_until_eof
from __future__ import print_function
from threading import Thread

if vis_client._record_running == True: # record thread is running
  vim.command( 'echom "An Record thread has already existed"' )
  vim.command( 'return 0' )
else: # create a new record thread
  vis_client._record_thread = Thread(target = vis_client.run_record,
                                      args = vis_client)
  if !vis_client._record_thread:
    vim.command( 'echom "create record thread Failed!"' )
    vim.command( 'return 0' )
  vim.command( 'let s:record_job_created = 1' )
  vim.command( 'return 1' )
EOF
endfunction


function! vis#StartRecord()
  if !s:vis_client_start
    s:SetUpServerAndClient()
  endif
  call s:CreateRecordJobIfNeed()

  exec s:python_until_eof
if vis_client._record_flag == True:
  vim.command( 'echom "record has already been started"' )
else:
  vis_client.start_record()
  vim.command( 'echom "start record"' )
EOF
endfunction

function! vis#StopRecord()
  if !s:vis_client_start || s:Pyeval( "vis_client._record_running" )
    echom "Record not started yet, Please call :StartRecord first"
    return
  endif

  exec s:python_command "vis_client.pause_record()"
  echom "Record paused"
endfunction

function! vim#DumpRecord()
  if !s:vis_client_start
    echom "Record not started yet, please call :StartRecord first"
    return
  endif

  if s:Pyeval( "vis_client._record_running" ):
    exec s:python_command "vis_client.pause_record()"
  endif

  l:dump_res = s:Pyeval( "vis_client.stop_recording" )
  echom l:dump_res
endfunction
