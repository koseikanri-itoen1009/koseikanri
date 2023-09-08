"""
--------------------------------------------------------------------------------

     [概要]
        Pythonで使用する共通基底クラス。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2023/03/31 Issue1.1
          更新履歴：   SCSK   吉岡           2022/07/20 Draft1A  初版
                       SCSK   吉岡           2022/10/31 Draft1B  仕様変更対応
                       SCSK   久保田         2023/02/22 Issue1.0 Issue化
                       SCSK   吉岡           2023/03/31 Issue1.1 業務日付更新対応

     [パラメータ]
        なし

--------------------------------------------------------------------------------
"""

import sys
import logging
import json
import os
import configparser
import datetime
import ast
import glob

from com.PyComnException import PyComnException

### Python共通基底クラス ###
class Xxccdcomn:

    """
    初期処理
      [パラメータ]
        機能名          ：exeName     string
        実行ファイルパス：exePath     string
      [戻り値]
        なし
      [例外]
        なし
    """
    def __init__(self, exeName, exePath):
        try:
            ## 環境変数ファイル生成
            self.inifile = configparser.SafeConfigParser()
            self.inifile.read(exePath + "/com/XXCCDCOMN.ini")
            self.hostName = os.environ.get("HOSTNAME")

            ## ログファイル生成
            dt_now = datetime.datetime.now()
            formatter = "%(asctime)s UTC : %(levelname)s : %(message)s"
            logName = self.getEnvValue("LOG_PATH") + exeName + "_" + dt_now.strftime("%Y%m") +".log"
            logging.basicConfig(filename=logName, format=formatter, level=logging.INFO)
            self.logging = logging

            ## 共通メッセージ生成
            msgFile = open(self.getEnvValue("COM_PATH") + "XXCCDMSG.json", "r")
            self.cmnMsg = json.load(msgFile)

            ## インスタンス変数初期値設定
            self.exeName = exeName
            self.endCd = self.getEnvConstValue("JP1_SUCC_CD")
            self.headers = {
                "Authorization": self.getEnvValue("AUTHORIZATION_BASIC"),
                "Content-Type": self.getEnvConstValue("CONTENT_TYPE_AJSON")
            }

            ## 開始ログ出力
            self.writeMsg("CCDI0001", [self.exeName])

        ## 例外処理
        except Exception as e:
            print(e)
            sys.exit(8)

    """
    環境変数ファイル値取得
      [パラメータ]
        変数ID：envId     string
      [戻り値]
        設定値            string
      [例外]
        なし
    """
    def getEnvValue(self, envId):
        try:
            ## 環境設定ファイルの設定値を返却
            return self.inifile.get(self.hostName, envId)
        except Exception:
            return ""

    """
    環境変数ファイル固定値取得
      [パラメータ]
        変数ID：envId      string
        変数ID：repStr     string
      [戻り値]
        設定値             string
      [例外]
        なし
    """
    def getEnvConstValue(self, envId):
        try:
            ## 環境設定ファイルの設定値を返却(セクション"const")
            return self.inifile.get("const", envId)
        except Exception:
            return ""

    """
    メッセージ変換
      [パラメータ]
        メッセージID  ：envId      string
        置換文字リスト：repStr     list
      [戻り値]
        変換後メッセージ           string
      [例外]
        なし
    """
    def getMsgReplace(self, msgId, repStr=[]):
        count = 1
        ## メッセージ取得
        msg = self.cmnMsg[msgId]
        ## 置換文字リストの件数分、メッセージ置換を実施
        for val in repStr:
            msg = msg.replace("{" + str(count) + "}", str(val))
            count += 1
        else:
            ## 置換後メッセージを返却
            return msg

    """
    メッセージ出力
      [パラメータ]
        メッセージID  ：envId      string
        置換文字リスト：repStr     list
      [戻り値]
        なし
      [例外]
        なし
    """
    def writeMsg(self, msgId, repStr=[]):
        ## メッセージIDよりメッセージステータス(4桁目)を取得
        eLv = "D" if len(msgId) < 4 else msgId[3]
        ## メッセージ変換を実施
        eMsg = self.getMsgReplace(msgId, repStr);
        ## メッセージステータスをもとに対象のloggingにてメッセージを出力
        if eLv == "I":
            self.logging.info(eMsg)
        elif eLv == "W":
            self.logging.warning(eMsg)
        elif eLv == "E":
            self.logging.error(eMsg)
        else:
            self.logging.debug(eMsg)

    """
    OICエラー判定
      [パラメータ]
        RESTAPIレスポンス：execResponse string
        置換文字リスト   ：msgParam     list
      [戻り値]
        なし
      [例外]
        PyComnException
    """
    def oicErrChk(self, execResponse, msgParam=[]):
        ## HTTPステータスコード取得
        stCode = execResponse.status_code
        ## HTTPステータスコードが200番台(正常)以外
        if str(stCode)[0] != "2":
            ## 終了コードにエラーを設定し、PyComnExceptionをスローする
            msgParam.append(stCode)
            self.endCd = self.getEnvConstValue("JP1_ERR_CD")
            raise PyComnException("CCDE0003", msgParam)

    """
    OICリターンコード判定
      [パラメータ]
        RESTAPIレスポンス：execResponse string
        置換文字リスト   ：msgParam     list
      [戻り値]
        変換後RESTAPIレスポンス         string
      [例外]
        PyComnException
    """
    def oicRtnCdChk(self, execResponse, msgParam=[]):
        ## RESTAPIレスポンスのJsonデコード変換を実施
        responseJson = execResponse.json()
        ## RESTAPIレスポンスよりリターンコードを取得
        retCode = responseJson["returnCode"]
        ## リターンコードが正常以外
        if str(retCode) != self.getEnvConstValue("RTNCD_SUCC_CD"):
            ## 終了コードにエラーを設定し、PyComnExceptionをスローする
            self.endCd = self.getEnvConstValue("JP1_ERR_CD")
            msgParam.extend([retCode, responseJson["message"], responseJson["errorDetail"]])
            raise PyComnException("CCDE0002", msgParam)
        ## Jsonデコード変換を実施したRESTAPIレスポンスを返却
        return responseJson

    """
    パラメータチェック、コマンドライン引数型変換
      [パラメータ]
        パラメータ名：paramName     string
        パラメータ値：paramVal      string
        必須：pReq                  boolean
        型：pType                   string
        桁：pLen                    int
      [戻り値]
        型変換後パラメータ値        入力パラメータ.型
      [例外]
        PyComnException
    """
    def paramChkAndConv(self, paramName, paramVal, pReq=False, pType="str", pLen=0):
        retVal = paramVal
        ## 必須チェック
        if pReq:
            if not retVal:
                self.endCd = self.getEnvConstValue("JP1_ERR_CD")
                raise PyComnException("CCDE0001", [paramName])

        ## 型チェック、変換
        try:
            if pType == "int":
                retVal = int(retVal, 10)
            elif pType == "list":
                retVal = ast.literal_eval(retVal)
            elif pType == "date":
                if retVal:
                    retVal = datetime.datetime.strptime(retVal, '%Y-%m-%d')

        except ValueError:
            self.endCd = self.getEnvConstValue("JP1_ERR_CD")
            raise PyComnException("CCDE0001", [paramName])

        ## 桁チェック
        if pLen > 0:
            if len(str(retVal)) > pLen: 
                self.endCd = self.getEnvConstValue("JP1_ERR_CD")
                raise PyComnException("CCDE0001", [paramName])

        ## 型チェックにて変換したパラメータ値の返却
        return retVal

    """
    終了処理
      [パラメータ]
        なし
      [戻り値]
        終了コード     int
      [例外]
        なし
    """
    def endExec(self):
        ## 終了ログ出力
        self.writeMsg("CCDI0003", [self.exeName])
        ## インスタンス変数.終了コードを返却
        return self.endCd

    """
    0バイトファイル判定
      [パラメータ]
        判定ファイル名：chkFileName     string
      [戻り値]
        判定結果                        bool
      [例外]
        なし
    """
    def isZeroByteFileChk(self, chkFileName):
        ## 判定結果を返却(0バイトの場合はTrue)
        return os.stat(chkFileName).st_size == 0

    """
    0バイトファイル削除処理
      [パラメータ]
        ファイルパス ：filePath     string
      [戻り値]
        判定結果                    bool
      [例外]
        なし
    """
    def delZeroByteFileExec(self, filePath):
        try:
            ## 全削除判定結果
            chkVal = True

            ## パラメータ.ファイルパスに格納されているファイル数分、以下の処理を繰り返し実行する。
            fileList = glob.glob(filePath + "/*.*")
            for files in fileList:
                ## ファイル0バイト判定
                if self.isZeroByteFileChk(files):
                    os.remove(files)
                else:
                    ## 0バイトファイル以外が存在した場合、全削除判定結果にFalseを設定
                    chkVal = False

            ## 判定結果を返却(0バイトの場合はTrue)
            return chkVal

        ## 例外処理
        except OSError as e:
            print(e)
