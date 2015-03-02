/*============================================================================
* ファイル名 : XxcmnConstants
* 概要説明   : 共通定数クラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-11 1.0  二瓶大輔     新規作成
* 2008-07-22 1.1  伊藤ひとみ   内部課題#32対応
* 2008-10-21 1.2  二瓶大輔     T_TE080_BPO_440 No14
* 2008-10-31 1.3  二瓶大輔     統合障害#405
* 2014-11-11 1.4  桐生和幸     E_本稼働_12237対応
*============================================================================
*/
package itoen.oracle.apps.xxcmn.util;
/***************************************************************************
 * 共通定数クラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.3
 ***************************************************************************
 */
public class XxcmnConstants 
{
  /** クラス名：XxcmnUtility */
  public static final String CLASS_XXCMN_UTILITY = "itoen.oracle.apps.xxcmn.util.XxcmnUtility";
  /** アプリケーション短縮名：XXCMN */
  public static final String APPL_XXCMN   = "XXCMN";
  /** アプリケーション短縮名：XXWIP */
  public static final String APPL_XXWIP   = "XXWIP";
  /** アプリケーション短縮名：XXPO */
  public static final String APPL_XXPO    = "XXPO";
  /** アプリケーション短縮名：XXINV */
  public static final String APPL_XXINV   = "XXINV";
  /** アプリケーション短縮名：XXWSH */
  public static final String APPL_XXWSH   = "XXWSH";
  /** メッセージ：APP-XXCMN-10123 */
  public static final String XXCMN10123   = "APP-XXCMN-10123";
  /** メッセージ：APP-XXCMN-10112 引当可能在庫不足確認 */
  public static final String XXCMN10112   = "APP-XXCMN-10112";
  /** メッセージ：APP-XXCMN-10147 */
  public static final String XXCMN10147   = "APP-XXCMN-10147";
  /** メッセージ：APP-XXCMN-10500 データ取得失敗エラー*/
  public static final String XXCMN10500   = "APP-XXCMN-10500";
  /** メッセージ：APP-XXCMN-05002 処理失敗エラー*/
  public static final String XXCMN05002   = "APP-XXCMN-05002";
  /** メッセージ：APP-XXCMN-10001 */
  public static final String XXCMN10001   = "APP-XXCMN-10001";
  /** メッセージ：APP-XXCMN-05001 */
  public static final String XXCMN05001   = "APP-XXCMN-05001";
  /** メッセージ：APP-XXCMN-10110 引当可能在庫数超過確認ワーニング */
  public static final String XXCMN10110   = "APP-XXCMN-10110";
  /** メッセージ：APP-XXCMN-00025 ダイアログメッセージ(改行有) */
  public static final String XXCMN00025   = "APP-XXCMN-00025";
  /** メッセージ：APP-XXCMN-00026 マイナス在庫チェックワーニングメッセージ */
  public static final String XXCMN00026   = "APP-XXCMN-00026";
// 2008-10-31 D.Nihei Add Start 統合障害#405
  /** メッセージ：APP-XXCMN-10601 在庫クローズエラー */
  public static final String XXCMN10601   = "APP-XXCMN-10601";
// 2008-10-31 D.Nihei Add End
// 2008-07-22 H.Itou Add START
  /** メッセージ：APP-XXCMN-10603 ケース入数エラー(トークン:なし) */
  public static final String XXCMN10603   = "APP-XXCMN-10603";
  /** メッセージ：APP-XXCMN-10604 ケース入数エラー(トークン:REQUEST_NO,ITEM_NO) */
  public static final String XXCMN10604   = "APP-XXCMN-10604";
  /** メッセージ：APP-XXCMN-10605 ケース入数エラー(トークン:ITEM_NO) */
  public static final String XXCMN10605   = "APP-XXCMN-10605";
// 2008-07-22 H.Itou Add END
// 2008-10-21 D.Nihei Add START T_TE080_BPO_440 No14
  /** メッセージ：APP-XXCMN-10013 設定項目エラー */
  public static final String XXCMN10013   = "APP-XXCMN-10013";
// 2008-10-21 D.Nihei Add END
  /** トークン：LOCATION */
  public static final String TOKEN_LOCATION     = "LOCATION";
  /** トークン：LOT */
  public static final String TOKEN_LOT          = "LOT";
  /** トークン：ITEM */
  public static final String TOKEN_ITEM         = "ITEM";
  /** トークン：TOKEN */
  public static final String TOKEN_TOKEN        = "TOKEN";
  /** トークン：TOKEN */
  public static final String TOKEN_PROCESS      = "PROCESS";
  /** トークン：DATE */
  public static final String TOKEN_DATE         = "DATE";
  /** トークン：MARK */
  public static final String TOKEN_MARK         = "MARK";
  /** トークン：STOCK */
  public static final String TOKEN_STOCK        = "STOCK";
  /** トークン：TABLE */
  public static final String TOKEN_TABLE        = "TABLE";
  /** トークン：KEY */
  public static final String TOKEN_KEY          = "KEY";
// 2008-07-22 H.Itou Add START
  /** トークン：REQUEST_NO */
  public static final String TOKEN_REQUEST_NO   = "REQUEST_NO";
  /** トークン：ITEM_NO */
  public static final String TOKEN_ITEM_NO      = "ITEM_NO";
// 2008-07-22 H.Itou Add END
  /** URL：ホーム画面 */
  public static final String URL_OAHOMEPAGE     = "OAHOMEPAGE";
  /** 定数：TRUE */
  public static final String STRING_TRUE        = "TRUE";
  /** 定数：FALSE */
  public static final String STRING_FALSE       = "FALSE";
  /** 定数：yes */
  public static final String STRING_YES         = "yes";
  /** 定数：no */
  public static final String STRING_NO          = "no";
  /** 定数：uiOnly */
  public static final String STRING_UI_ONLY     = "uiOnly";
  /** 定数：Y */
  public static final String STRING_Y           = "Y";
  /** 定数：Y */
  public static final String STRING_N           = "N";
  /** API戻り値：0 */
  public static final String API_RETURN_NORMAL  = "0";
  /** API戻り値：1 */
  public static final String API_RETURN_WARN    = "1";
  /** API戻り値：2 */
  public static final String API_RETURN_ERROR   = "2";
  /** API戻り値：S */
  public static final String API_STATUS_SUCCESS = "S";
  /** API戻り値：E */
  public static final String API_STATUS_ERROR   = "E";
  /** API戻り値：1 パラメータチェックエラー */
  public static final String API_PARAM_ERROR    = "1";
  /** API戻り値：-1 配車解除失敗 */
  public static final String API_CANCEL_CARRER_ERROR = "-1";
  /** 共通関数戻り値：1 */
  public static final String RETURN_SUCCESS     = "1";
  /** 共通関数戻り値：2 */
  public static final String RETURN_WARN        = "2";
  /** 共通関数戻り値：0 */
  public static final String RETURN_NOT_EXE     = "0";
  /** 共通関数戻り値：E1 */
  public static final String RETURN_ERR1        = "E1";
  /** 共通関数戻り値：E2 */
  public static final String RETURN_ERR2        = "E2";
  /** 定数：ドット */
  public static final String DOT                = ".";
  /** 定数：0 */
  public static final String STRING_ZERO        = "0";
  /** 定数：1 */
  public static final String STRING_ONE         = "1";
// 2014-11-11 K.Kiriu Add START
  /** 定数：2 */
  public static final String STRING_TWO         = "2";
// 2014-11-11 K.Kiriu Add END
  /** 対象対象外区分：0 対象外 */
  public static final String OBJECT_OFF   = "0";
  /** 対象対象外区分：1 対象 */
  public static final String OBJECT_ON    = "1";
  /** 定数：改行コード */
  public static final String CHANGING_LINE_CODE = "<br>";
  /** 固定値：CSV */
  public static final String CSV_NM             = "CSV";
  /** VIEW名：OPM品目情報VIEW */
  public static final String VIEW_NAME_XXCMN_ITEM_MST_V      = "OPM品目情報VIEW";
  /** VIEW名：仕入先情報VIEW */
  public static final String VIEW_NAME_XXCMN_VENDORS_V       = "仕入先情報VIEW";
  /** VIEW名：クイックコード情報VIEW */
  public static final String VIEW_NAME_XXCMN_LOOKUP_VALUES_V = "クイックコード情報VIEW";
  /** 業務種別：1 出荷 */
  public static final String BIZ_TYPE_WSH   = "1";  
  /** 業務種別：2 支給 */
  public static final String BIZ_TYPE_PROV  = "2";  
  /** 業務種別：3 移動 */
  public static final String BIZ_TYPE_MOV   = "3";  
}