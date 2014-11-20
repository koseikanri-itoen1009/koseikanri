/*============================================================================
* ファイル名 : XxinvConstants
* 概要説明   : INV共通定数
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-21 1.0  高梨雅史     新規作成
* 2008-06-18 1.1  大橋孝郎     不具合指摘事項修正
* 2008-07-10 1.2  伊藤ひとみ   内部変更
* 2008-09-24 1.3  伊藤ひとみ   統合テスト 指摘156
*============================================================================
*/
package itoen.oracle.apps.xxinv.util;
import oracle.jbo.domain.Number;
/***************************************************************************
 * INV共通定数クラスです。
 * @author  ORACLE 高梨雅史
 * @version 1.3
 ***************************************************************************
 */
public class XxinvConstants 
{
  /** トランザクション名：Xxinv990001jTxn */
  public static final String TXN_XXINV990001J = "Xxinv990001jTxn";
  /** トランザクション名：Xxinv510001jTxn */
  public static final String TXN_XXINV510001J = "Xxinv510001jTxn";
  /** トランザクション名：Xxinv510002jTxn */
  public static final String TXN_XXINV510002J = "Xxinv510002jTxn";
  /** クラス名：XxinvUtility */
  public static final String CLASS_XXINV_UTILITY   = "itoen.oracle.apps.xxinv.util.XxinvUtility";
  /** クラス名：XxpoSupplierResultsMakeAMImpl */
  public static final String CLASS_AM_XXINV510001J = "itoen.oracle.apps.xxinv.xxinv510001j.server.XxinvMovementResultsHdAMImpl";
  /** セーブポイント名：XXINV510001J */
  public static final String SAVE_POINT_XXINV510001J  = "XXINV510001J";
  /** URL：入出庫実績要約画面 */
  public static final String URL_XXINV510001JS = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsPG";
  /** URL：入出庫実績ヘッダ画面 */
  public static final String URL_XXINV510001JH = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsHdPG";
  /** URL：入出庫実績明細画面 */
  public static final String URL_XXINV510001JL = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsLnPG";
  /** URL：出庫ロット明細画面 */
  public static final String URL_XXINV510002J_1 = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510002j/webui/XxinvMovementShippedLotPG";
  /** URL：入庫ロット明細画面 */
  public static final String URL_XXINV510002J_2 = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510002j/webui/XxinvMovementShipToLotPG";
  /** URLパラメータID：検索用移動ヘッダID */
  public static final String URL_PARAM_SEARCH_MOV_ID   = "pSearchMovHdrId";
  /** URLパラメータID：更新フラグ */
  public static final String URL_PARAM_UPDATE_FLAG   = "pUpdateFlag";
  /** URLパラメータID：従業員区分 */
  public static final String URL_PARAM_PEOPLE_CODE   = "pPeopleCode";
  /** URLパラメータID：実績データ区分 */
  public static final String URL_PARAM_ACTUAL_FLAG   = "pActualFlg";
  /** URLパラメータID：製品識別区分 */
  public static final String URL_PARAM_PRODUCT_FLAG   = "pProductFlg";
  /** URLパラメータID：商品区分 */
  public static final String URL_PARAM_ITEM_CLASS   = "pItemClass";
  /** URLパラメータID：検索用移動明細ID */
  public static final String URL_PARAM_SEARCH_MOV_LINE_ID = "pSearchMovLineId";
  /** URLパラメータID：前画面URL */
  public static final String URL_PARAM_PREV_URL     = "pPrevUrl";
  /** 処理フラグ：1 登録 */
  public static final String PROCESS_FLAG_I = "1";
  /** 処理フラグ：2 更新 */
  public static final String PROCESS_FLAG_U = "2";
  /** 登録フラグ：1 指示あり新規登録 */
  public static final String INPUT_FLAG_1 = "1";
  /** 登録フラグ：2 指示なし新規登録 */
  public static final String INPUT_FLAG_2 = "2";
  /** 従業員区分：1 内部 */
  public static final String PEOPLE_CODE_I = "1";
  /** 従業員区分：2 外部 */
  public static final String PEOPLE_CODE_O = "2";
  /** ステータス：01 依頼中 */
  public static final String STATUS_01 = "01";
  /** ステータス：02 依頼済 */
  public static final String STATUS_02 = "02";
  /** ステータス：03 調整中 */
  public static final String STATUS_03 = "03";
  /** ステータス：04 出庫報告有 */
  public static final String STATUS_04 = "04";
  /** ステータス：05 入庫報告有 */
  public static final String STATUS_05 = "05";
  /** ステータス：06 入出庫報告有 */
  public static final String STATUS_06 = "06";
  /** ステータス：99 取消 */
  public static final String STATUS_99 = "99";
  /** 移動タイプ：1 積送あり */
  public static final String MOV_TYPE_1 = "1";
  /** 移動タイプ：2 積送なし */
  public static final String MOV_TYPE_2 = "2";
  /** 通知ステータスコード：10 未通知 */
  public static final String NOTIFSTATSU_CODE_1O = "10";
  /** 通知ステータス：未通知 */
  public static final String NOTIFSTATSU_NAME_1O = "未通知";
  /** 運賃区分：0 無 */
  public static final String FREIGHT_CHARGE_CLASS_0 = "0";
  /** 運賃区分：1 有 */
  public static final String FREIGHT_CHARGE_CLASS_1 = "1";
  /** 重量容積区分コード：1 重量 */
  public static final String WEIGHT_CAPACITY_CLASS_CODE_1 = "1";
  /** 重量容積区分：1 重量 */
  public static final String WEIGHT_CAPACITY_CLASS_NAME_1 = "重量";
  /** 重量容積区分コード：2 容積 */
  public static final String WEIGHT_CAPACITY_CLASS_CODE_2 = "2";
  /** 重量容積区分：2 容積 */
  public static final String WEIGHT_CAPACITY_CLASS_NAME_2 = "容積";
  /** 実績計上済フラグ：Y 実績計上済 */
  public static final String COMP_ACTUAL_FLG_Y = "Y";
  /** 実績計上済フラグ：N 実績未計上 */
  public static final String COMP_ACTUAL_FLG_N = "N";
  /** 品目区分：5 製品 */
  public static final String ITEM_CLASS_5 = "5";
  /** レコードタイプ：10 指示 */
  public static final String RECORD_TYPE_10 = "10";
  /** レコードタイプ：20 出庫実績 */
  public static final String RECORD_TYPE_20 = "20";
  /** レコードタイプ：30 入庫実績 */
  public static final String RECORD_TYPE_30 = "30";
  /** 起動パラメータ名 */
  public static final String XXINV990001J_PARAM = "CONTENT_TYPE";
  /** メッセージ：APP-XXINV-10005 コンカレント起動エラー */
  public static final String XXINV10005   = "APP-XXINV-10005";
  /** メッセージ：APP-XXINV-10006 コンカレント起動正常メッセージ */
  public static final String XXINV10006   = "APP-XXINV-10006";
  /** メッセージ：APP-XXINV-10009 データ取得エラー */
  public static final String XXINV10009   = "APP-XXINV-10009";
  /** メッセージ：APP-XXINV-10131 実績日未入力メッセージ */
  public static final String XXINV10131   = "APP-XXINV-10131";
  /** メッセージ：APP-XXINV-10034 異なる日付メッセージ */
  public static final String XXINV10034   = "APP-XXINV-10034";
  /** メッセージ：APP-XXINV-10043 検索条件未指定エラー */
  public static final String XXINV10043   = "APP-XXINV-10043";
  /** メッセージ：APP-XXINV-10055 日付逆転エラー */
  public static final String XXINV10055   = "APP-XXINV-10055";
  /** メッセージ：APP-XXINV-10058 非稼働日エラー */
  public static final String XXINV10058   = "APP-XXINV-10058";
  /** メッセージ：APP-XXINV-10063 品目重複エラー */
  public static final String XXINV10063   = "APP-XXINV-10063";
  /** メッセージ：APP-XXINV-10064 保管倉庫未入力メッセージ */
  public static final String XXINV10064   = "APP-XXINV-10064";
  /** メッセージ：APP-XXINV-10066 未来日エラー(出庫日) */
  public static final String XXINV10066   = "APP-XXINV-10066";
  /** メッセージ：APP-XXINV-10067 未来日エラー(着日) */
  public static final String XXINV10067   = "APP-XXINV-10067";
  /** メッセージ：APP-XXINV-10120 在庫期間エラー */
  public static final String XXINV10120   = "APP-XXINV-10120";
  /** メッセージ：APP-XXINV-10158 更新完了メッセージ */
  public static final String XXINV10158   = "APP-XXINV-10158";
  /** メッセージ：APP-XXINV-10159 ロック失敗エラー */
  public static final String XXINV10159   = "APP-XXINV-10159";
  /** メッセージ：APP-XXINV-10030 マイナス値エラーメッセージ */
  public static final String XXINV10030   = "APP-XXINV-10030";
  /** メッセージ：APP-XXINV-10033 ロット情報取得エラーメッセージ */
  public static final String XXINV10033   = "APP-XXINV-10033";
  /** メッセージ：APP-XXINV-10129 ロットNo重複エラー */
  public static final String XXINV10129   = "APP-XXINV-10129";
  /** メッセージ：APP-XXINV-10130 ロット逆転防止チェックエラーメッセージ */
  public static final String XXINV10130   = "APP-XXINV-10130";
  /** メッセージ：APP-XXINV-10128 必須エラー */
  public static final String XXINV10128   = "APP-XXINV-10128";
  /** メッセージ：APP-XXINV-10127 重量容積小口個数更新エラーメッセージ */
  public static final String XXINV10127   = "APP-XXINV-10127";
  /** メッセージ：APP-XXINV-10160 数値不正エラー */
  public static final String XXINV10160   = "APP-XXINV-10160";
  /** メッセージ：APP-XXINV-10161 登録完了メッセージ */
  public static final String XXINV10161   = "APP-XXINV-10161";
  /** メッセージ：APP-XXINV-10165 ロットステータスエラーメッセージ */
  public static final String XXINV10165 = "APP-XXINV-10165";
  /** メッセージ：APP-XXINV-10061 必須チェックエラーメッセージ */
  public static final String XXINV10061 = "APP-XXINV-10061"; // add ver1.1
  /** メッセージ：APP-XXINV-10119 入出庫保管倉庫エラーメッセージ */
  public static final String XXINV10119 = "APP-XXINV-10119"; // add ver1.3
  /** トークン：SHIP_DATE */
  public static final String TOKEN_SHIP_DATE       = "SHIP_DATE";
  /** トークン：ARRIVAL_DATE */
  public static final String TOKEN_ARRIVAL_DATE    = "ARRIVAL_DATE";
  /** トークン：TAGET_DATE */
  public static final String TOKEN_TARGET_DATE     = "TARGET_DATE";
  /** トークン：PROGRAM */
  public static final String TOKEN_PROGRAM         = "PROGRAM";
  /** トークン：ID */
  public static final String TOKEN_ID              = "ID";
  /** トークン：MSG */
  public static final String TOKEN_MSG              = "MSG";
  /** トークン：ITEM */
  public static final String TOKEN_ITEM = "ITEM";
  /** トークン：LOT */
  public static final String TOKEN_LOT = "LOT";
  /** トークン：LOCATION */
  public static final String TOKEN_LOCATION = "LOCATION";
  /** トークン：REVDATE */
  public static final String TOKEN_REVDATE = "REVDATE";
  /** トークン：LOT_STATUS */
  public static final String TOKEN_LOT_STATUS = "LOT_STATUS";
  /** トークン名称：出庫日(実績) */
  public static final String TOKEN_NAME_SHIP_DATE    = "出庫日(実績)";
  /** トークン名称：着日(実績) */
  public static final String TOKEN_NAME_ARRIVAL_DATE = "着日(実績)";
  /** トークン名称：移動入出庫実績登録処理 */
  public static final String TOKEN_NAME_MOV_ACTUAL_MAKE = "移動入出庫実績登録処理";
  /** トークン名称：最大配送区分 */
  public static final String TOKEN_NAME_MAX_SHIP_METHOD = "最大配送区分";
  /** トークン名称：品目 */
  public static final String TOKEN_NAME_ITEM = "品目";  // add ver1.1
  /** ページタイトルの固定部分 (「ファイルアップロード：　」)*/
  public static final String DISP_TEXT = "ファイルアップロード：";
  /** 参照タイプ タイプ名称 */
  public static final String LOOKUP_TYPE = "XXINV_FILE_OBJECT";
  /** 文書タイプ：10 出荷依頼 */
  public static final String DOC_TYPE_SHIP    = "10";
  /** 文書タイプ：20 移動 */
  public static final String DOC_TYPE_MOVE    = "20";
  /** 文書タイプ：30 支給指示 */
  public static final String DOC_TYPE_SUPPLY  = "30";
  /** 実績データ区分：1 出庫実績から起動 */
  public static final String ACTUAL_FLAG_DELI   = "1";
  /** 実績データ区分：2 入庫実績から起動 */
  public static final String ACTUAL_FLAG_SCOC   = "2";
  /** 製品識別区分：1 製品 */
  public static final String PRODUCT_FLAG_PROD = "1";
  /** 製品識別区分：2 製品以外 */
  public static final String PRODUCT_FLAG_NOT_PROD = "2";
  /** ロット管理区分：1 ロット管理品 */
  public static final String LOT_CTL_Y = "1";
  /** ロット管理区分：0 ロット管理外品 */
  public static final String LOT_CTL_N = "0";
  /** デフォルトロット：0 */
  public static final Number DEFAULT_LOT = new Number(0);
  /** 商品区分：1 リーフ */
  public static final String PROD_CLASS_CODE_LEAF = "1";
  /** 商品区分：2 ドリンク */
  public static final String PROD_CLASS_CODE_DRINK = "2";
  /** 共通関数戻り値：0 */
  public static final Number RETURN_SUCCESS     = new Number(0);
  /** 共通関数戻り値：1 */
  public static final Number RETURN_NOT_EXE     = new Number(1);
  /** シーケンス : 「移動ヘッダID用」　 */
  public static final String XXINV_MOV_HDR_S1 = "xxinv_mov_hdr_s1";
  /** コンカレント名：移動入出庫実績登録処理　 */
  public static final String CONC_NAME_XXINV570001C = "XXINV570001C";// add ver1.2
}