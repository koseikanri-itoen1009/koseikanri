/*============================================================================
* ファイル名 : XxwshConstants
* 概要説明   : 出荷・引当/配車共通定数
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
* 2008-06-27 1.1  伊藤ひとみ   結合不具合TE080_400#157対応
* 2008-09-25 1.2  伊藤ひとみ   T_TE080_BPO_400指摘93対応
* 2014-11-11 1.3  桐生和幸     E_本稼働_12237対応
*============================================================================
*/
package itoen.oracle.apps.xxwsh.util;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 出荷・引当/配車共通定数クラスです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.2
 ***************************************************************************
 */
public class XxwshConstants 
{
  /** クラス名：XxwshUtility */
  public static final String CLASS_XXWSH_UTILITY  = "itoen.oracle.apps.xxwsh.util.XxwshUtility";
  /** クラス名：XxwshShipLotInputAMImpl */
  public static final String CLASS_AM_XXWSH920001J  = "itoen.oracle.apps.xxwsh.xxwsh920001j.server.XxwshShipLotInputAMImpl";
  /** URL：引当ロット入力画面 */
  public static final String URL_XXWSH920002JH    = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920002j/webui/XxwshReserveLotInputPG";
  /** URL：入出荷実績ロット入力画面(出荷実績) */
  public static final String URL_XXWSH920001J_1   = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920001j/webui/XxwshShipLotInputPG";
  /** URL：入出荷実績ロット入力画面(入庫実績) */
  public static final String URL_XXWSH920001J_2   = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920001j/webui/XxwshStockLotInputPG";
  /** トランザクション名：XXWSH920001JTXN */
  public static final String TXN_XXWSH920001J     = "xxwsh920001jTxn";
  /** トランザクション名：XXWSH920002JTXN */
  public static final String TXN_XXWSH920002J     = "xxwsh920002jTxn";
  /** URLパラメータID：呼出画面区分 */
  public static final String URL_PARAM_CALL_PICTURE_KBN   = "wCallPictureKbn";
  /** URLパラメータID：明細ID */
  public static final String URL_PARAM_LINE_ID            = "wLineId";
  /** URLパラメータID：ヘッダ更新日時 */
  public static final String URL_PARAM_HEADER_UPDATE_DATE = "wHeaderUpdateDate";
  /** URLパラメータID：明細更新日時 */
  public static final String URL_PARAM_LINE_UPDATE_DATE   = "wLineUpdateDate";
  /** URLパラメータID：起動区分 */
  public static final String URL_PARAM_EXE_KBN            = "wExeKbn";
  /** URLパラメータID：依頼No */
  public static final String URL_PARAM_REQ_NO             = "wReqNo";
  //xxwsh920001jメッセージ
  /** メッセージ：APP-XXWSH-13310 必須入力パラメータ未入力エラーメッセージ */
  public static final String XXWSH13310 = "APP-XXWSH-13310";
  /** メッセージ：APP-XXWSH-13311 入力パラメータ書式エラーメッセージ */
  public static final String XXWSH13311 = "APP-XXWSH-13311";
  /** メッセージ：APP-XXWSH-13302 必須エラー */
  public static final String XXWSH13302 = "APP-XXWSH-13302";
  /** メッセージ：APP-XXWSH-13303 入力値エラー */
  public static final String XXWSH13303 = "APP-XXWSH-13303";
  /** メッセージ：APP-XXWSH-13313 数値不正エラー */
  public static final String XXWSH13313 = "APP-XXWSH-13313";
  /** メッセージ：APP-XXWSH-13312 ロット情報取得エラーメッセージ */
  public static final String XXWSH13312 = "APP-XXWSH-13312";
  /** メッセージ：APP-XXWSH-13301 ロットステータスエラーメッセージ */
  public static final String XXWSH13301 = "APP-XXWSH-13301";
  /** メッセージ：APP-XXWSH-13305 ロットNo重複エラー */
  public static final String XXWSH13305 = "APP-XXWSH-13305";
  /** メッセージ：APP-XXWSH-13304 在庫会計期間チェックエラーメッセージ */
  public static final String XXWSH13304 = "APP-XXWSH-13304";
  /** メッセージ：APP-XXWSH-13306 ロックエラーメッセージ */
  public static final String XXWSH13306 = "APP-XXWSH-13306";
  /** メッセージ：APP-XXWSH-13308 重量容積小口個数更新関数エラーメッセージ */
  public static final String XXWSH13308 = "APP-XXWSH-13308";
  /** メッセージ：APP-XXWSH-33301 ロット逆転防止チェックエラー */
  public static final String XXWSH33301 = "APP-XXWSH-33301";
  /** メッセージ：APP-XXWSH-33304 登録完了メッセージ */
  public static final String XXWSH33304 = "APP-XXWSH-33304";
  /** メッセージ：APP-XXWSH-13314 コンカレント登録エラー */
  public static final String XXWSH13314 = "APP-XXWSH-13314";
  //xxwsh920002jメッセージ
  /** メッセージ：APP-XXWSH-12901 引当数量不一致エラーメッセージ */
  public static final String XXWSH12901 = "APP-XXWSH-12901";
  /** メッセージ：APP-XXWSH-12902 数値不正エラー */
  public static final String XXWSH12902 = "APP-XXWSH-12902";
  /** メッセージ：APP-XXWSH-12903 入力パラメータ書式エラーメッセージ */
  public static final String XXWSH12903 = "APP-XXWSH-12903";
  /** メッセージ：APP-XXWSH-12904 必須入力パラメータ未入力エラーメッセージ */
  public static final String XXWSH12904 = "APP-XXWSH-12904";
  /** メッセージ：APP-XXWSH-12905 マイナス数量エラーメッセージ */
  public static final String XXWSH12905 = "APP-XXWSH-12905";
  /** メッセージ：APP-XXWSH-12906 引当可能数変更エラーメッセージ */
  public static final String XXWSH12906 = "APP-XXWSH-12906";
  /** メッセージ：APP-XXWSH-12907 変更済エラーメッセージ */
  public static final String XXWSH12907 = "APP-XXWSH-12907";
  /** メッセージ：APP-XXWSH-12908 ロックエラー */
  public static final String XXWSH12908 = "APP-XXWSH-12908";
  /** メッセージ：APP-XXWSH-12909 積載効率エラーメッセージ */
  public static final String XXWSH12909 = "APP-XXWSH-12909";
  /** メッセージ：APP-XXWSH-12910 最大配送区分取得エラーメッセージ */
  public static final String XXWSH12910 = "APP-XXWSH-12910";
  /** メッセージ：APP-XXWSH-12911 必須エラー */
  public static final String XXWSH12911 = "APP-XXWSH-12911";
  /** メッセージ：APP-XXWSH-32901 ロット逆転ワーニング */
  public static final String XXWSH32901 = "APP-XXWSH-32901";
  /** メッセージ：APP-XXWSH-32902 鮮度条件ワーニング */
  public static final String XXWSH32902 = "APP-XXWSH-32902";
  /** メッセージ：APP-XXWSH-32903 指示数量更新メッセージ */
  public static final String XXWSH32903 = "APP-XXWSH-32903";
  /** メッセージ：APP-XXWSH-32904 登録完了メッセージ */
  public static final String XXWSH32904 = "APP-XXWSH-32904";
  /** トークン：PARM_NAME */
  public static final String TOKEN_PARM_NAME = "PARM_NAME";
  /** トークン：LOT_STATUS */
  public static final String TOKEN_LOT_STATUS = "LOT_STATUS";
  /** トークン：DATE */
  public static final String TOKEN_DATE = "DATE";
  /** トークン：TABLE */
  public static final String TOKEN_TABLE = "TABLE";
  /** トークン：ITEM */
  public static final String TOKEN_ITEM = "ITEM";
  /** トークン：LOT */
  public static final String TOKEN_LOT = "LOT";
  /** トークン：LOCATION */
  public static final String TOKEN_LOCATION = "LOCATION";
  /** トークン：REVDATE */
  public static final String TOKEN_REVDATE = "REVDATE";
  /** トークン：PRG_NAME */
  public static final String TOKEN_PRG_NAME = "PRG_NAME";
  /** トークン：ERR_CODE */
  public static final String TOKEN_ERR_CODE = "ERR_CODE";
  /** トークン：ERR_MSG */
  public static final String TOKEN_ERR_MSG = "ERR_MSG";
  /** トークン：KUBUN */
  public static final String TOKEN_KUBUN = "KUBUN";
  /** トークン：LOADING_EFFICIENCY */
  public static final String TOKEN_LOADING_EFFICIENCY = "LOADING_EFFICIENCY";
  /** トークン：CODE_KBN1 */
  public static final String TOKEN_CODE_KBN1 = "CODE_KBN1";
  /** トークン：SHIP_FROM */
  public static final String TOKEN_SHIP_FROM = "SHIP_FROM";
  /** トークン：CODE_KBN2 */
  public static final String TOKEN_CODE_KBN2 = "CODE_KBN2";
  /** トークン：SHIP_TO */
  public static final String TOKEN_SHIP_TO = "SHIP_TO";
  /** トークン：SHIP_DATE */
  public static final String TOKEN_SHIP_DATE = "SHIP_DATE";
  /** トークン：SHIP_TYPE */
  public static final String TOKEN_SHIP_TYPE = "SHIP_TYPE";
  /** トークン：ARRIVAL_DATE */
  public static final String TOKEN_ARRIVAL_DATE = "ARRIVAL_DATE";
  /** トークン：PROD_CLASS */
  public static final String TOKEN_PROD_CLASS = "PROD_CLASS";
  /** トークン名称：明細ID */
  public static final String TOKEN_NAME_LINE_ID             = "明細ID";
  /** トークン名称：呼出画面区分 */
  public static final String TOKEN_NAME_CALL_PICTURE_KBN    = "呼出画面区分";
  /** トークン名称：明細更新日時 */
  public static final String TOKEN_NAME_LINE_UPDATE_DATE    = "明細更新日時";
  /** トークン名称：ヘッダ更新日時 */
  public static final String TOKEN_NAME_HEADER_UPDATE_DATE  = "ヘッダ更新日時";
  /** トークン名称：起動区分 */
  public static final String TOKEN_NAME_EXE_KBN = "起動区分";
  /** トークン名称：コンカレント名 */
  public static final String TOKEN_NAME_PGM_NAME_420001C = "出荷依頼/出荷実績作成処理";
  /** トークン名称：重量 */
  public static final String TOKEN_NAME_WEIGHT = "重量";
  /** トークン名称：容積 */
  public static final String TOKEN_NAME_CAPACITY = "容積";
  /** トークン名称：配送先 */
  public static final String TOKEN_NAME_DELIVER_TO = "配送先";
  /** トークン名称：入庫先 */
  public static final String TOKEN_NAME_SHIP_TO = "入庫先";

  /** レコードタイプ：10 指示 */
  public static final String RECORD_TYPE_INST = "10";
  /** レコードタイプ：20 出庫実績 */
  public static final String RECORD_TYPE_DELI = "20";
  /** レコードタイプ：30 入庫実績 */
  public static final String RECORD_TYPE_STOC = "30";
  /** レコードタイプ：40 投入済 */
  public static final String RECORD_TYPE_INVE = "40";
  /** 文書タイプ：10 出荷依頼 */
  public static final String DOC_TYPE_SHIP    = "10";
  /** 文書タイプ：20 移動 */
  public static final String DOC_TYPE_MOVE    = "20";
  /** 文書タイプ：30 支給指示 */
  public static final String DOC_TYPE_SUPPLY  = "30";
  /** 品目タイプ：1 原料 */
  public static final String ITEM_TYPE_MTL    = "1";
  /** 品目タイプ：2 資材 */
  public static final String ITEM_TYPE_SHZ    = "2";
  /** 品目タイプ：4 半製品 */
  public static final String ITEM_TYPE_HALF   = "4";
  /** 品目タイプ：5 製品 */
  public static final String ITEM_TYPE_PROD   = "5";
  /** 呼出画面区分：1 出荷依頼入力画面 */
  public static final String CALL_PIC_KBN_SHIP_INPUT  = "1";
  /** 呼出画面区分：2 支給指示作成画面 */
  public static final String CALL_PIC_KBN_PROD_CREATE = "2";
  /** 呼出画面区分：3 移動依頼/指示入力画面 */
  public static final String CALL_PIC_KBN_MOVE_ORDER  = "3";
  /** 呼出画面区分：4 出庫実績画面 */
  public static final String CALL_PIC_KBN_DELI        = "4";
  /** 呼出画面区分：5 入庫実績画面 */
  public static final String CALL_PIC_KBN_STOC        = "5";
  /** 呼出画面区分：6 支給返品画面 */
  public static final String CALL_PIC_KBN_RETURN      = "6";
  /** 日付フォーマット */
  public static final String DATE_FORMAT = "YYYY/MM/DD HH24:MI:SS";
  /** ロット管理区分：1 ロット管理品 */
  public static final String LOT_CTL_Y = "1";
  /** ロット管理区分：0 ロット管理外品 */
  public static final String LOT_CTL_N = "0";
  /** デフォルトロット：0 */
  public static final Number DEFAULT_LOT = new Number(0);
  /** 有償金額確定区分：1 確定 */
  public static final String AMOUNT_FIX_CLASS_Y = "1";
  /** 有償金額確定区分：2 未確定 */
  public static final String AMOUNT_FIX_CLASS_N = "2";
  /** 出荷支給受払カテゴリ：01 見本出庫 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_SAMPLE_SHIP = "01";
  /** 出荷支給受払カテゴリ：02 廃棄出庫 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_JUNK_SHIP   = "02";
  /** 出荷支給受払カテゴリ：03 倉替入庫 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CHANGE_STOC = "03";
  /** 出荷支給受払カテゴリ：04 返品入庫 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_RET_STOC    = "04";
  /** 出荷支給受払カテゴリ：05 有償出荷 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP   = "05";
  /** 出荷支給受払カテゴリ：06 有償返品 */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET    = "06";
  /** 出荷依頼ステータス：01 入力中 */
  public static final String TRANSACTION_STATUS_INPUT = "01";
  /** 出荷依頼ステータス：02 拠点確定 */
  public static final String TRANSACTION_STATUS_HUB   = "02";
  /** 出荷依頼ステータス：03 締め済 */
  public static final String TRANSACTION_STATUS_CLOSE = "03";
  /** 出荷依頼ステータス：04 出荷実績計上済 */
  public static final String TRANSACTION_STATUS_ADD   = "04";
  /** 出荷依頼ステータス：99 取消 */
  public static final String TRANSACTION_STATUS_DEL   = "99";
  /** 支給依頼ステータス：05 入力中 */
  public static final String XXPO_TRANSACTION_STATUS_INPUT = "05";
  /** 支給依頼ステータス：06 入力完了 */
  public static final String XXPO_TRANSACTION_STATUS_HUB   = "06";
  /** 支給依頼ステータス：07 受領済 */
  public static final String XXPO_TRANSACTION_STATUS_CLOSE = "07";
  /** 支給依頼ステータス：08 出荷実績計上済 */
  public static final String XXPO_TRANSACTION_STATUS_ADD   = "08";
  /** 支給依頼ステータス：99 取消 */
  public static final String XXPO_TRANSACTION_STATUS_DEL   = "99";
  /** 対象_対象外区分：0 対象外 */
  public static final String INCLUDE_EXCLUD_EXCLUD  = "0";
  /** 対象_対象外区分：1 対象 */
  public static final String INCLUDE_EXCLUD_INCLUDE = "1";
  /** 商品区分：1 リーフ */
  public static final String PROD_CLASS_CODE_LEAF = "1";
  /** 商品区分：2 ドリンク */
  public static final String PROD_CLASS_CODE_DRINK = "2";
  /** 受注カテゴリ：受注 */
  public static final String ORDER_CATEGORY_CODE_ORDER = "ORDER";
  /** 共通関数戻り値：0 */
  public static final Number RETURN_SUCCESS     = new Number(0);
  /** 共通関数戻り値：1 */
  public static final Number RETURN_NOT_EXE     = new Number(1);
  /** 拠点実績有無区分：1 売上拠点*/
  public static final String LOCATION_REL_CODE_SALE = "1";
  /** シーケンス : 「移動ロット詳細アドオンID用」　 */
  public static final String XXINV_MOV_LOT_S1 = "xxinv_mov_lot_s1";
  /** テーブル名：受注ヘッダアドオン*/
  public static final String TABLE_NAME_ORDER_HEADERS = "受注ヘッダアドオン";
  /** テーブル名：受注明細アドオン*/
  public static final String TABLE_NAME_ORDER_LINES = "受注明細アドオン";
  /** テーブル名：移動依頼/指示ヘッダ(アドオン)*/
  public static final String TABLE_NAME_MOV_HEADERS = "移動依頼/指示ヘッダ(アドオン)";
  /** テーブル名：移動依頼/指示明細(アドオン)*/
  public static final String TABLE_NAME_MOV_LINES = "移動依頼/指示明細(アドオン)";
  /** 入出庫換算単位使用区分 1:対象*/
  public static final String CONV_UNIT_USE_KBN_INCLUDE = "1";
  /** 一括解除ボタン押下フラグ 1:押下済*/
  public static final String PACKAGE_LIFT_FLAG_INCLUDE = "1";
  /** 指示数量更新フラグ 1:更新対象*/
  public static final String INSTRUCT_QTY_UPD_FLAG_INCLUDE = "1";
  /** 指示数量更新フラグ 0:更新対象外*/
  public static final String INSTRUCT_QTY_UPD_FLAG_EXCLUD = "0";
  /** コード区分 4:倉庫*/
  public static final String CODE_KBN_4 = "4";
  /** コード区分 9:配送先*/
  public static final String CODE_KBN_9 = "9";
  /** コード区分 11:支給先*/
  public static final String CODE_KBN_11 = "11";
  /** 重量容積区分 : 「1 : 重量」　 */
  public static final String WGHT_CAPA_CLASS_WEIGHT   = "1";
  /** 重量容積区分 : 「2 : 容積」　 */
  public static final String WGHT_CAPA_CLASS_CAPACITY = "2";
  /** 積載オーバー区分 : 「1 : 積載オーバ」　 */
  public static final String LOADING_OVER_CLASS_OVER = "1";
  /** 警告区分 : 「30 : ロット逆転」　 */
  public static final String WARNING_CLASS_LOT = "30";
  /** 警告区分 : 「40 : 鮮度条件」　 */
  public static final String WARNING_CLASS_FRESH = "40";
  /** ロット逆転処理種別 : 「1 : 出荷(指示)」　 */
  public static final String LOT_BIZ_CLASS_SHIP_INS = "1";
  /** ロット逆転処理種別 : 「5 : 移動(指示)」　 */
  public static final String LOT_BIZ_CLASS_MOVE_INS = "5";
  /** 自動手動引当区分：「20 :手動引当」　 */
  public static final String AM_RESERVE_CLASS_MAN = "20";
  /** 在庫調整区分：「1 :」　 */
  public static final String ADJS_CLASS_1 = "1"; // 2008-09-25 H.Itou Add
  /** 在庫調整区分：「2 :」　 */
  public static final String ADJS_CLASS_2 = "2"; // 2008-09-25 H.Itou Add
  /** コンカレント名：出荷依頼/出荷実績作成処理　 */
  public static final String CONC_NAME_XXWSH420001C = "XXWSH420001C";// 2008-06-27 H.Itou ADD
// 2014-11-11 K.Kiriu Add Start
  /** 直送外顧客：-1 */
  public static final Number NOT_DIRECT_CUST = new Number(-1);
// 2014-11-11 K.Kiriu Add End
}