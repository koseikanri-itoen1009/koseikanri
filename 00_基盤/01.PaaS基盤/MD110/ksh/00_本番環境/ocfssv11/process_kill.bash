#!/bin/bash

#対象ディレクトリにてプロセスIDの取得
lsof_output=$(lsof +D /uspg)
target_pids=($(echo "$lsof_output" | awk 'NR>1 {print $2}'))

#プロセスIDが取得できたか確認
if [ ${#target_pids[@]} -gt 0 ]; then
  #プロセスの強制終了
  kill -9 "${target_pids[@]}"
  #終了ステータスの確認
  if [ $? -eq 0 ]; then
      echo "プロセスが正常に終了しました。"
  else
      echo "プロセスの終了に失敗しました。"
  fi
else
  echo "対象ディレクトリにプロセスが見つかりませんでした。"
fi