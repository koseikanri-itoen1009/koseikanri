"""
--------------------------------------------------------------------------------

     [概要]
        業務日付更新のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   久保田         2023/03/27 Issue1.0
          更新履歴：   SCSK   久保田         2023/03/27 Issue1.0 初版

     [戻り値]
        0 : 正常
        8 : 異常

     [パラメータ]
        業務日付                             str

     [使用方法]
        /uspg/jp1/zb/py/prodoicuser/XXCCD029.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import os
import datetime

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD029", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        operationDate = com.paramChkAndConv("業務日付", args[1], False, "date", 0)

        ##### 業務日付更新 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "operationDate" : operationDate.strftime("%Y-%m-%d") if operationDate else ""
        })
        ## RESTAPI実行
        apiResponse = requests.request("POST"
            , com.getEnvValue("OIC_HOST") + "/ic/api/integration/v1/flows/rest/XXCCD028/1.0/RestOperationDateUpdate"
            , headers=com.headers
            , data=execPayload)

        ## RESTAPIエラー判定
        com.oicErrChk(apiResponse, ["業務日付更新"])

        ## リターンコードエラー判定
        com.oicRtnCdChk(apiResponse, ["業務日付更新"])

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["業務日付更新"])

    ## 例外判定
    except PyComnException as e1:
      com.writeMsg(e1.msgId, e1.repStr)

    except Exception as e:
      com.logging.exception(e)
      com.endCd = com.getEnvConstValue("JP1_ERR_CD")

    finally:
      ## 終了処理
      return com.endExec()

if __name__ == "__main__":
    ## Main実行
    sys.exit(int(main()))
