/*============================================================================
* ファイル名 : XxwipConstants
* 概要説明   : 生産共通定数
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-27 1.0  二瓶大輔     新規作成
* 2008-09-10 1.1  二瓶大輔     結合テスト指摘対応No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.util;
/***************************************************************************
 * 生産共通定数クラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class XxwipConstants 
{
  /** メッセージ：APP-XXWIP-00007 */
  public static final String XXWIP00007   = "APP-XXWIP-00007";
  /** メッセージ：APP-XXWIP-10007 */
  public static final String XXWIP10007   = "APP-XXWIP-10007";
  /** メッセージ：APP-XXWIP-10008 */
  public static final String XXWIP10008   = "APP-XXWIP-10008";
  /** メッセージ：APP-XXWIP-10014 */
  public static final String XXWIP10014   = "APP-XXWIP-10014";
  /** メッセージ：APP-XXWIP-10023 */
  public static final String XXWIP10023   = "APP-XXWIP-10023";
  /** メッセージ：APP-XXWIP-10049 */
  public static final String XXWIP10049   = "APP-XXWIP-10049";
  /** メッセージ：APP-XXWIP-10058 */
  public static final String XXWIP10058   = "APP-XXWIP-10058";
  /** メッセージ：APP-XXWIP-10061 */
  public static final String XXWIP10061   = "APP-XXWIP-10061";
  /** メッセージ：APP-XXWIP-10062 */
  public static final String XXWIP10062   = "APP-XXWIP-10062";
  /** メッセージ：APP-XXWIP-10063 */
  public static final String XXWIP10063   = "APP-XXWIP-10063";
  /** メッセージ：APP-XXWIP-10064 */
  public static final String XXWIP10064   = "APP-XXWIP-10064";
  /** メッセージ：APP-XXWIP-10065 */
  public static final String XXWIP10065   = "APP-XXWIP-10065";
  /** メッセージ：APP-XXWIP-10081 */
  public static final String XXWIP10081   = "APP-XXWIP-10081";
// 2008-09-10 v1.1 D.Nihei Add Start
  /** メッセージ：APP-XXWIP-10082 */
  public static final String XXWIP10082   = "APP-XXWIP-10082";
  /** メッセージ：APP-XXWIP-10083 */
  public static final String XXWIP10083   = "APP-XXWIP-10083";
  /** メッセージ：APP-XXWIP-10084 */
  public static final String XXWIP10084   = "APP-XXWIP-10084";
  /** メッセージ：APP-XXWIP-10085 */
  public static final String XXWIP10085   = "APP-XXWIP-10085";
// 2008-09-10 v1.1 D.Nihei Add End
  /** メッセージ：APP-XXWIP-30001 */
  public static final String XXWIP30001   = "APP-XXWIP-30001";
  /** メッセージ：APP-XXWIP-30002 */
  public static final String XXWIP30002   = "APP-XXWIP-30002";
// 2008-09-10 v1.1 D.Nihei Add Start
  /** メッセージ：APP-XXWIP-30011 */
  public static final String XXWIP30011   = "APP-XXWIP-30011";
  /** メッセージ：APP-XXWIP-40002 */
  public static final String XXWIP40002   = "APP-XXWIP-40002";
  /** トークン：STATUS */
  public static final String TOKEN_STATUS     = "STATUS";
// 2008-09-10 v1.1 D.Nihei Add End
  /** トークン：ITEM */
  public static final String TOKEN_ITEM       = "ITEM";
  /** トークン：API_NAME */
  public static final String TOKEN_API_NAME   = "API_NAME";
  /** トークン名称：品目 */
  public static final String TOKEN_NAME_ITEM  = "品目";
  /** URL：出来高実績入力画面 */
  public static final String URL_XXWIP200001J = "OA.jsp?page=/itoen/oracle/apps/xxwip/xxwip200001j/webui/XxwipVolumeActualPG";
  /** URL：投入実績入力画面 */
  public static final String URL_XXWIP200002J = "OA.jsp?page=/itoen/oracle/apps/xxwip/xxwip200002j/webui/XxwipInvestActualPG";
	/** URLパラメータID：検索用バッチID */
	public static final String URL_PARAM_SEARCH_BATCH_ID   = "pSearchBatchId";
	/** URLパラメータID：検索用生産原料詳細ID */
	public static final String URL_PARAM_SEARCH_MTL_DTL_ID = "pSearchMtlDtlId";
	/** URLパラメータID：遷移用バッチID */
	public static final String URL_PARAM_MOVE_BATCH_ID     = "pMoveBatchId";
	/** URLパラメータID：検索用バッチID */
	public static final String URL_PARAM_TAB_TYPE = "pTabType";
// 2008-09-10 v1.1 D.Nihei Add Start
	/** URLパラメータID：引当解除用バッチID */
	public static final String URL_PARAM_CAN_BATCH_ID         = "pCanBatchId";
	/** URLパラメータID：引当解除用生産原料詳細ID */
	public static final String URL_PARAM_CAN_MTL_DTL_ID       = "pCanMtlDtlId";
	/** URLパラメータID：引当解除用生産原料詳細アドオンID */
	public static final String URL_PARAM_CAN_MTL_DTL_ADDON_ID = "pCanMtlDtlAddonId";
	/** URLパラメータID：引当解除用処理ID */
	public static final String URL_PARAM_CAN_TRANS_ID         = "pCanTransId";
// 2008-09-10 v1.1 D.Nihei Add End
	/** パラメータID：検索ボタン */
	public static final String QS_SEARCH_BTN      = "QsSearch";
	/** ボタンID : 適用ボタン */
	public static final String GO_BTN             = "Go";
	/** ボタンID : 取消ボタン */
	public static final String CANCEL_BTN         = "Cancel";
	/** アクションID : 投入品目ポップリスト */
	public static final String CHANGE_INVEST_BTN  = "ChangeItemInvest";
	/** アクションID : 打込品目ポップリスト */
	public static final String CHANGE_RE_INVEST_BTN = "ChangeItemReInvest";
	/** アイコンID : 削除アイコン */
	public static final String DELETE_ICON        = "deleteRow";
	/** パラメータID：バッチID */
	public static final String PARAM_SC_BATCH_ID  = "QsSearchBatchId";
	/** パラメータID：タブタイプ */
	public static final String PARAM_TAB_TYPE     = "TAB_TYPE";
	/** パラメータID：生産原料詳細ID */
	public static final String PARAM_MTL_DTL_ID   = "MTL_DTL_ID";
	/** パラメータID：バッチID */
	public static final String PARAM_BATCH_ID     = "BATCH_ID";
	/** タブタイプ：投入情報タブ */
	public static final String TAB_TYPE_INVEST    = "0";
	/** タブタイプ：打込情報タブ */
	public static final String TAB_TYPE_REINVEST  = "1";
	/** タブタイプ：副産物情報タブ */
	public static final String TAB_TYPE_CO_PROD   = "2";
	/** ラインタイプ：完成品 */
	public static final String LINE_TYPE_PROD     = "1";
	/** ラインタイプ：投入品 */
	public static final String LINE_TYPE_INVEST   = "-1";
	/** ラインタイプ：副産物 */
	public static final String LINE_TYPE_CO_PROD  = "2";
	/** ラインタイプ：投入品 */
	public static final int LINE_TYPE_INVEST_NUM   = -1;
	/** ラインタイプ：副産物 */
	public static final int LINE_TYPE_CO_PROD_NUM  = 2;
	/** 業務ステータス：1 保留中 */
	public static final String DUTY_STATUS_HRT    = "1";
	/** 業務ステータス：2 依頼済 */
	public static final String DUTY_STATUS_IRZ    = "2";
	/** 業務ステータス：3 手配済 */
	public static final String DUTY_STATUS_THZ    = "3";
	/** 業務ステータス：4 指図済 */
	public static final String DUTY_STATUS_SZZ    = "4";
	/** 業務ステータス：5 確認済 */
	public static final String DUTY_STATUS_KNZ    = "5";
	/** 業務ステータス：6 受付済 */
	public static final String DUTY_STATUS_UTZ    = "6";
	/** 業務ステータス：7 完了 */
	public static final String DUTY_STATUS_COM    = "7";
	/** 業務ステータス：8 クローズ */
	public static final String DUTY_STATUS_CLS    = "8";
	/** 業務ステータス：-1 取消 */
	public static final String DUTY_STATUS_CAN    = "-1";
	/** 品質ステータス：10 未判定 */
	public static final String QT_STATUS_NON_JUDG = "10";
	/** 品質ステータス：50 合格 */
	public static final String QT_STATUS_PASS     = "50";
	/** 内外区分：1 自社 */
	public static final String IN_OUT_TYPE_JISHA  = "1";
	/** 内外区分：2 委託先 */
	public static final String IN_OUT_TYPE_ITAKU  = "2";
	/** 委託計算区分：1 出来高実績 */
	public static final String TRUST_CALC_TYPE_VOLUME = "1";
	/** 委託計算区分：2 投入実績 */
	public static final String TRUST_CALC_TYPE_INVEST = "2";
	/** 試験有無区分：1 有 */
	public static final String QT_TYPE_ON         = "1";
	/** 試験有無区分：0 無 */
	public static final String QT_TYPE_OFF        = "0";
  /** クラス名：XxwipUtility */
  public static final String CLASS_XXWIP_UTILITY   = "itoen.oracle.apps.xxwip.util.XxwipUtility";
  /** クラス名：XxwipVolumeActualAMImpl */
  public static final String CLASS_AM_XXWIP200001J = "itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipVolumeActualAMImpl";
  /** クラス名：XxwipInvestActualAMImpl */
  public static final String CLASS_AM_XXWIP200002J = "itoen.oracle.apps.xxwip.xxwip200002j.server.XxwipInvestActualAMImpl";
	/** セーブポイント名：XXWIP200001J */
	public static final String SAVE_POINT_XXWIP200001J  = "xxwip200001j";
	/** レコードタイプ：1 挿入 */
	public static final String RECORD_TYPE_INS   = "0";
	/** レコードタイプ：2 更新 */
	public static final String RECORD_TYPE_UPD   = "1";
	/** 品目タイプ：1 原料 */
	public static final String ITEM_TYPE_MTL     = "1";
	/** 品目タイプ：2 資材 */
	public static final String ITEM_TYPE_SHZ     = "2";
	/** 品目タイプ：4 半製品 */
	public static final String ITEM_TYPE_HALF    = "4";
	/** 品目タイプ：5 製品 */
	public static final String ITEM_TYPE_PROD    = "5";
	/** トランザクション名：XXWIP200001JTxn */
	public static final String TXN_XXWIP200001J  = "xxwip200001jTxn";
	/** トランザクション名：XXWIP200002JTxn */
	public static final String TXN_XXWIP200002J  = "xxwip200002jTxn";

}
