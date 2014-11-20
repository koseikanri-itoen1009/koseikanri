/*============================================================================
* ファイル名 : XxpoConstants
* 概要説明   : 仕入共通定数
* バージョン : 1.9
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-10 1.0  伊藤ひとみ     新規作成
* 2008-06-09 1.1  二瓶大輔　     変更要求#42対応
* 2008-06-30 1.2  二瓶大輔　     内部変更要求#146,147対応
* 2008-07-11 1.3  伊藤ひとみ     内部変更要求#153対応(メッセージ追加)
* 2008-07-11 1.3  二瓶大輔　     ST#421対応(メッセージ追加)
* 2008-07-30 1.4  伊藤ひとみ     内部変更要求#176(メッセージ追加)
* 2008-10-23 1.5  伊藤ひとみ     T_TE08_BPO_340 指摘5
* 2009-02-06 1.6  伊藤ひとみ     本番障害#1147対応
* 2009-03-06 1.7  飯田  甫       本番障害#1131対応
* 2009-05-12 1.8  吉元  強樹     本番障害#1458対応
* 2011-06-01 1.9  窪    和重     本番障害#1786対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.util;
/***************************************************************************
 * 仕入共通定数クラスです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.7
 ***************************************************************************
 */
public class XxpoConstants 
{
  /** クラス名：XxpoUtility */
  public static final String CLASS_XXPO_UTILITY   = "itoen.oracle.apps.xxpo.util.XxpoUtility";
  /** クラス名：XxpoSupplierResultsMakeAMImpl */
  public static final String CLASS_AM_XXPO320001J = "itoen.oracle.apps.xxpo.xxpo320001j.server.XxpoSupplierResultsMakeAMImpl";
  /** クラス名：XxpoPoConfirmAMImpl */
  public static final String CLASS_AM_XXPO350001J = "itoen.oracle.apps.xxpo.xxpo350001j.server.XxpoPoConfirmAMImpl";
  /** クラス名：Xxpo370002J */
  public static final String CLASS_AM_XXPO370002J = "itoen.oracle.apps.xxpo.xxpo370002j.server.XxpoInspectLotSearchAMImpl";
  /** クラス名：XxpoOrderReceiptAMImpl */
  public static final String CLASS_AM_XXPO310001J = "itoen.oracle.apps.xxpo.xxpo310001j.server.XxpoOrderReceiptAMImpl";
  /** クラス名：XxpoOrderReceiptAMImpl */
  public static final String CLASS_AM_XXPO440001J = "itoen.oracle.apps.xxpo.xxpo440001j.server.XxpoProvisionRequestAMImpl";
  /** クラス名：XxpoShippedResultAMImpl */
  public static final String CLASS_AM_XXPO441001J = "itoen.oracle.apps.xxpo.xxpo441001j.server.XxpoShippedResultAMImpl";
  /** クラス名：XxpoOrderReceiptAMImpl */
  public static final String CLASS_AM_XXPO442001J = "itoen.oracle.apps.xxpo.xxpo442001j.server.XxpoShipToResultAMImpl";
  /** クラス名：XxpoProvisionRtnSummaryAMImpl */
  public static final String CLASS_AM_XXPO443001J = "itoen.oracle.apps.xxpo.xxpo443001j.server.XxpoProvisionRtnSummaryAMImpl";
  /** セーブポイント名：XXPO340001J */
  public static final String SAVE_POINT_XXPO340001J  = "XXPO340001J";
  /** セーブポイント名：XXPO340002J */
  public static final String SAVE_POINT_XXPO340002J  = "XXPO340002J";
  /** セーブポイント名：XXPO310001J */
  public static final String SAVE_POINT_XXPO310001J  = "XXPO310001J";  
  /** セーブポイント名：XXPO320001J */
  public static final String SAVE_POINT_XXPO320001J  = "XXPO320001J";  
  /** セーブポイント名：XXPO350001J */
  public static final String SAVE_POINT_XXPO350001J  = "XXPO350001J";
  /** セーブポイント名：XXPO370001J */
  public static final String SAVE_POINT_XXPO370001J  = "XXPO370001J";
  /** セーブポイント名：XXPO370002J */
  public static final String SAVE_POINT_XXPO370002J  = "XXPO370002J";
  /** セーブポイント名：XXPO440001J */
  public static final String SAVE_POINT_XXPO440001J  = "XXPO440001J";  
  /** セーブポイント名：XXPO443001J */
  public static final String SAVE_POINT_XXPO443001J  = "XXPO443001J";  
  /** トランザクション名：XXPO310001JTXN */
  public static final String TXN_XXPO310001J  = "xxpo310001jTxn";
  /** トランザクション名：XXPO320001JTXN */
  public static final String TXN_XXPO320001J  = "xxpo320001jTxn";
  /** トランザクション名：XXPO340001JTXN */
  public static final String TXN_XXPO340001J  = "xxpo340001jTxn";
  /** トランザクション名：XXPO350001JTxn */
  public static final String TXN_XXPO350001J  = "Xxpo350001jTxn";
  /** トランザクション名：XXPO370001JTxn */
  public static final String TXN_XXPO370001J  = "xxpo370001jTxn";
  /** トランザクション名：XXPO370002JTxn */
  public static final String TXN_XXPO370002J  = "Xxpo370002jTxn";
  /** トランザクション名：XXPO440001JTXN */
  public static final String TXN_XXPO440001J  = "xxpo440001jTxn";
  /** トランザクション名：XXPO441001JTXN */
  public static final String TXN_XXPO441001J  = "xxpo441001jTxn";
  /** トランザクション名：XXPO442001JTXN */
  public static final String TXN_XXPO442001J  = "xxpo442001jTxn";
  /** トランザクション名：XXPO443001JTXN */
  public static final String TXN_XXPO443001J  = "xxpo443001JTxn";
  /** メッセージ：APP-XXPO-10001 数値不正エラー */
  public static final String XXPO10001   = "APP-XXPO-10001";
  /** メッセージ：APP-XXPO-10002 必須項目エラー */
  public static final String XXPO10002   = "APP-XXPO-10002";
  /** メッセージ：APP-XXPO-10003 登録可否チェック */
  public static final String XXPO10003   = "APP-XXPO-10003";  
  /** メッセージ：APP-XXPO-10004 在庫クローズエラー */
  public static final String XXPO10004   = "APP-XXPO-10004";  
  /** メッセージ：APP-XXPO-10005 ロット登録済みエラー */
  public static final String XXPO10005   = "APP-XXPO-10005";  
  /** メッセージ：APP-XXPO-10006 更新処理失敗エラー */
  public static final String XXPO10006   = "APP-XXPO-10006";  
  /** メッセージ：APP-XXPO-10007 登録処理失敗エラー */
  public static final String XXPO10007   = "APP-XXPO-10007";  
  /** メッセージ：APP-XXPO-10008 更新処理失敗エラー２ */
  public static final String XXPO10008   = "APP-XXPO-10008"; 
  /** メッセージ：APP-XXPO-10024 コンカレント起動失敗エラー */
  public static final String XXPO10024   = "APP-XXPO-10024";  
  /** メッセージ：APP-XXPO-10025 コンカレント登録エラー */
  public static final String XXPO10025   = "APP-XXPO-10025";  
  /** メッセージ：APP-XXPO-10031 ロット管理品目対象外エラー */
  public static final String XXPO10031   = "APP-XXPO-10031";  
  /** メッセージ：APP-XXPO-10035 検索条件チェック */
  public static final String XXPO10035   = "APP-XXPO-10035";
  /** メッセージ：APP-XXPO-10040 絞め処理後の日付指定2 */
  public static final String XXPO10040   = "APP-XXPO-10040";
  /** メッセージ：APP-XXPO-10045 仕入実績作成処理中断1 */
  public static final String XXPO10045   = "APP-XXPO-10045";
  /** メッセージ：APP-XXPO-10046 仕入実績作成処理中断2 */
  public static final String XXPO10046   = "APP-XXPO-10046";
  /** メッセージ：APP-XXPO-10055 受入取引処理起動エラー */
  public static final String XXPO10055   = "APP-XXPO-10055";
  /** メッセージ：APP-XXPO-10061 受入年月妥当性エラー */
  public static final String XXPO10061   = "APP-XXPO-10061";
  /** メッセージ：APP-XXPO-10068 正数チェックエラー */
  public static final String XXPO10068   = "APP-XXPO-10068";
  /** メッセージ：APP-XXPO-10071 組合(2項目)チェックエラー */
  public static final String XXPO10071   = "APP-XXPO-10071";
  /** メッセージ：APP-XXPO-10078 対象データ未選択エラー */
  public static final String XXPO10078   = "APP-XXPO-10078";
  /** メッセージ：APP-XXPO-10088 納入日が未来日付のため受入不可エラー */
  public static final String XXPO10088   = "APP-XXPO-10088";
  /** メッセージ：APP-XXPO-10096 必須チェックエラー */
  public static final String XXPO10096   = "APP-XXPO-10096";
  /** メッセージ：APP-XXPO-10110 ロット採番エラー */
  public static final String XXPO10110   = "APP-XXPO-10110";  
  /** メッセージ：APP-XXPO-10113 代表価格表未取得エラー */
  public static final String XXPO10113   = "APP-XXPO-10113";  
  /** メッセージ：APP-XXPO-10117 運送業者導出エラー */
  public static final String XXPO10117   = "APP-XXPO-10117";  
  /** メッセージ：APP-XXPO-10118 日付不正チェックエラー */
  public static final String XXPO10118   = "APP-XXPO-10118";  
  /** メッセージ：APP-XXPO-10119 在庫クローズエラー3 */
  public static final String XXPO10119   = "APP-XXPO-10119";  
  /** メッセージ：APP-XXPO-10120 積載効率チェックエラー */
  public static final String XXPO10120   = "APP-XXPO-10120";
  /** メッセージ：APP-XXPO-10121 ステータスエラー */
  public static final String XXPO10121   = "APP-XXPO-10121";
  /** メッセージ：APP-XXPO-10124 通知ステータスエラー */
  public static final String XXPO10124   = "APP-XXPO-10124";
  /** メッセージ：APP-XXPO-10125 金額確定済エラー */
  public static final String XXPO10125   = "APP-XXPO-10125";
  /** メッセージ：APP-XXPO-10128 指示確定不可エラー */
  public static final String XXPO10128   = "APP-XXPO-10128";
  /** メッセージ：APP-XXPO-10130 実績入力済エラー */
  public static final String XXPO10130   = "APP-XXPO-10130";
  /** メッセージ：APP-XXPO-10138 ロック失敗エラー2 */
  public static final String XXPO10138   = "APP-XXPO-10138";
  /** メッセージ：APP-XXPO-10140 更新不可エラー(納入日クローズ) */
  public static final String XXPO10140   = "APP-XXPO-10140";
  /** メッセージ：APP-XXPO-10141 更新不可エラー(金額確定済み) */
  public static final String XXPO10141   = "APP-XXPO-10141";
  /** メッセージ：APP-XXPO-10142 更新不可エラー(取消済) */
  public static final String XXPO10142   = "APP-XXPO-10142";
  /** メッセージ：APP-XXPO-10144 対象データ未選択エラー */
  public static final String XXPO10144   = "APP-XXPO-10144";
  /** メッセージ：APP-XXPO-10145 ステータスエラー */
  public static final String XXPO10145   = "APP-XXPO-10145";
  /** メッセージ：APP-XXPO-10146 明細件数なしエラー */
  public static final String XXPO10146   = "APP-XXPO-10146";
  /** メッセージ：APP-XXPO-10151 重複エラー */
  public static final String XXPO10151   = "APP-XXPO-10151";
  /** メッセージ：APP-XXPO-10152 削除不可エラー */
  public static final String XXPO10152   = "APP-XXPO-10152";
  /** メッセージ：APP-XXPO-10153 数量マイナスエラー */
  public static final String XXPO10153   = "APP-XXPO-10153";
  /** メッセージ：APP-XXPO-10200 単価取得エラー（品目トークン有り） */
  public static final String XXPO10200   = "APP-XXPO-10200";
  /** メッセージ：APP-XXPO-10201 単価取得エラー2（品目トークン無し） */
  public static final String XXPO10201   = "APP-XXPO-10201";
  /** メッセージ：APP-XXPO-10202 ロットステータスエラー */
  public static final String XXPO10202   = "APP-XXPO-10202";
  /** メッセージ：APP-XXPO-10203 実績存在エラー */
  public static final String XXPO10203   = "APP-XXPO-10203";
  /** メッセージ：APP-XXPO-10204 納入日が未来日のため受入不可エラー2 */
  public static final String XXPO10204   = "APP-XXPO-10204";
  /** メッセージ：APP-XXPO-10205 絞日超過エラー */
  public static final String XXPO10205   = "APP-XXPO-10205";
  /** メッセージ：APP-XXPO-10206 一括出庫確認 */
  public static final String XXPO10206   = "APP-XXPO-10206";
  /** メッセージ：APP-XXPO-10207 出庫実績存在エラー */
  public static final String XXPO10207   = "APP-XXPO-10207";
  /** メッセージ：APP-XXPO-10208 更新不可エラー4 */
  public static final String XXPO10208   = "APP-XXPO-10208";
  /** メッセージ：APP-XXPO-10209 一括受入確認 */
  public static final String XXPO10209   = "APP-XXPO-10209";
  /** メッセージ：APP-XXPO-10210 ロットステータスエラー */
  public static final String XXPO10210   = "APP-XXPO-10210";
  /** メッセージ：APP-XXPO-10214 複数選択エラー */
  public static final String XXPO10214   = "APP-XXPO-10214";
  /** メッセージ：APP-XXPO-10244 未来日エラー */
  public static final String XXPO10244   = "APP-XXPO-10244";
  /** メッセージ：APP-XXPO-10249 日付大小比較エラー(入庫日) */
  public static final String XXPO10249   = "APP-XXPO-10249";
  /** メッセージ：APP-XXPO-30040 発注情報未選択 */
  public static final String XXPO30040   = "APP-XXPO-30040";
  /** メッセージ：APP-XXPO-30041 登録完了メッセージ */
  public static final String XXPO30041   = "APP-XXPO-30041"; 
  /** メッセージ：APP-XXPO-30042 更新完了メッセージ */
  public static final String XXPO30042   = "APP-XXPO-30042";
  /** メッセージ：APP-XXPO-30050 処理完了メッセージ */
  public static final String XXPO30050   = "APP-XXPO-30050"; 
  /** メッセージ：APP-XXPO-40029 削除確認 */
  public static final String XXPO40029   = "APP-XXPO-40029"; 
  /** メッセージ：APP-XXPO-40032 全数出庫確認 */
  public static final String XXPO40032   = "APP-XXPO-40032"; 
  /** メッセージ：APP-XXPO-40033 全数入庫確認 */
  public static final String XXPO40033   = "APP-XXPO-40033"; 
  /** メッセージ：APP-XXPO-40035 仕入承諾確認 */
  public static final String XXPO40035   = "APP-XXPO-40035";
  /** メッセージ：APP-XXPO-40036 発注承諾確認 */
  public static final String XXPO40036   = "APP-XXPO-40036";
// 2008-07-11 H.Itou Add START
  /** メッセージ：APP-XXPO-10254 納入日未来日エラー1 */
  public static final String XXPO10253   = "APP-XXPO-10253";
  /** メッセージ：APP-XXPO-10254 納入日未来日エラー2 */
  public static final String XXPO10254   = "APP-XXPO-10254";
// 2008-07-11 H.Itou Add END
// 2008-07-11 D.Nihei Add START
  /** メッセージ：APP-XXPO-10227 数値0以下エラー */
  public static final String XXPO10227   = "APP-XXPO-10227";
// 2008-07-11 D.Nihei Add END
// 2008-07-30 H.Itou Add START
  /** メッセージ：APP-XXPO-10264 出庫日未来日エラー */
  public static final String XXPO10264   = "APP-XXPO-10264";
  /** メッセージ：APP-XXPO-10265 入庫日未来日エラー */
  public static final String XXPO10265   = "APP-XXPO-10265";
// 2008-07-30 H.Itou Add END
// 2008-10-23 H.Itou Add START
  /** メッセージ：APP-XXPO-10274 相手先在庫管理対象NULLエラー */
  public static final String XXPO10274   = "APP-XXPO-10274";
  /** メッセージ：APP-XXPO-10275 相手先在庫管理対象不一致エラー */
  public static final String XXPO10275   = "APP-XXPO-10275";
// 2008-10-23 H.Itou Add END
// 2009-02-06 H.Itou Add START
  /** メッセージ：APP-XXPO-10278 品目未登録エラー */
  public static final String XXPO10278   = "APP-XXPO-10278";
// 2009-02-06 H.Itou Add END
// 2009-03-06 H.Iida Add START
  /** メッセージ：APP-XXPO-10286 明細指示数不正エラー */
  public static final String XXPO10286   = "APP-XXPO-10286";
// 2009-03-06 H.Iida Add END
// 2009-05-12 v1.8 T.Yoshimoto Add Start 本番#1458
  /** メッセージ：APP-XXPO-10291 処理起動エラー */
  public static final String XXPO10291   = "APP-XXPO-10291";
// 2009-05-12 v1.8 T.Yoshimoto Add End 本番#1458
// 2011-06-01 v1.9 K.Kubo Add Start 本番#1786
  /** メッセージ：APP-XXPO-10294 処理起動エラー */
  public static final String XXPO10294   = "APP-XXPO-10294";
// 2011-06-01 v1.9 K.Kubo Add End   本番#1786

  /** トークン：ENTRY */
  public static final String TOKEN_ENTRY       = "ENTRY";
  /** トークン：DATA */
  public static final String TOKEN_DATA        = "DATA";
  /** トークン：INFO_NAME */
  public static final String TOKEN_INFO_NAME   = "INFO_NAME";
  /** トークン：PARAMETER */
  public static final String TOKEN_PARAMETER   = "PARAMETER";
  /** トークン：VALUE */
  public static final String TOKEN_VALUE       = "VALUE";
  /** トークン：ITEM */
  public static final String TOKEN_ITEM        = "ITEM";
  /** トークン：ITEM_NO */
  public static final String TOKEN_ITEM_NO     = "ITEM_NO";
  /** トークン：PRG_NAME */
  public static final String TOKEN_PRG_NAME    = "PRG_NAME";
  /** トークン：ERRKEY */
  public static final String TOKEN_ERRKEY      = "ERRKEY";
  /** トークン：ERRMSG */
  public static final String TOKEN_ERRMSG      = "ERRMSG";
  /** トークン：PROCESS */
  public static final String TOKEN_PROCESS     = "PROCESS";
  /** トークン：PROC_NAME */
  public static final String TOKEN_PROC_NAME   = "PROC_NAME";
// 2008-07-30 H.Itou Add START
  /** トークン：TOKEN */
  public static final String TOKEN             = "TOKEN";
// 2008-07-30 H.Itou Add END
// 2009-02-06 H.Itou Add START
  /** トークン：ITEM_VALUE */
  public static final String ITEM_VALUE        = "ITEM_VALUE";
// 2009-02-06 H.Itou Add END
  /** トークン名称：取引先 */
  public static final String TOKEN_NAME_ENTRY  = "取引先";
  /** トークン名称：出来高報告 */
  public static final String TOKEN_NAME_DATA   = "出来高報告";
  /** トークン名称：ENTRY1 */
  public static final String TOKEN_ENTRY1      = "ENTRY1";
  /** トークン名称：ENTRY2 */
  public static final String TOKEN_ENTRY2      = "ENTRY2";
  /** トークン名称：入数 */
  public static final String TOKEN_NAME_ITEM_AMOUNT = "入数";
  /** トークン名称：出庫数 */
  public static final String TOKEN_NAME_L_S_AMOUNT  = "出庫数";
  /** トークン名称：出荷実績作成処理 */
  public static final String TOKEN_NAME_DS_RESULTS_MAKE = "出荷実績作成処理";
  /** トークン名称：ロット情報作成 */
  public static final String TOKEN_NAME_CREATE_LOT_INFO = "ロット情報作成";
  /** トークン名称：ロット情報更新 */
  public static final String TOKEN_NAME_UPDATE_LOT_INFO = "ロット情報更新";
  /** トークン名称：ロット情報 */
  public static final String TOKEN_NAME_LOT_INFO = "ロット情報";
  /** トークン名称：ロットNo */
  public static final String TOKEN_NAME_LOT_NO   = "ロットNo";
  /** トークン名称：品質検査依頼情報作成 */
  public static final String TOKEN_NAME_CREATE_QT_INSPECTION = "品質検査依頼情報作成";
  /** トークン名称：品質検査依頼情報更新 */
  public static final String TOKEN_NAME_UPDATE_QT_INSPECTION = "品質検査依頼情報更新";
  /** トークン名称：品質検査依頼情報 */
  public static final String TOKEN_NAME_QT_INSPECTION_INFO   = "品質検査依頼情報";
  /** トークン名称：検査依頼No. */
  public static final String TOKEN_NAME_REQ_NO = "検査依頼No";
  /** トークン名称：取引先 */
  public static final String TOKEN_NAME_VENDOR = "取引先";
  /** トークン名称：品目 */
  public static final String TOKEN_NAME_ITEM   = "品目";
  /** トークン名称：製造日/仕入日 */
  public static final String TOKEN_NAME_PRODUCT_DATE   = "製造日/仕入日";
  /** トークン名称：取引先コード */
  public static final String TOKEN_NAME_VENDOR_CODE    = "取引先コード";
  /** トークン名称：品目コード */
  public static final String TOKEN_NAME_ITEM_CODE      = "品目コード";
  /** トークン名称：内容 */
  public static final String TOKEN_NAME_LOOKUP_MEANING = "内容";
  /** トークン名称：受入数量 */
  public static final String TOKEN_NAME_RCV_RTN_QUANTITYT  = "受入数量";
  /** トークン名称：納入日 */
  public static final String TOKEN_NAME_TXNS_DATE   = "納入日";
  /** トークン名称：受入取引処理 */
  public static final String TOKEN_NAME_RVCTP       = "受入取引処理";
  /** トークン名称：登録処理 */
  public static final String TOKEN_NAME_INS   = "登録処理";
  /** トークン名称：更新処理 */
  public static final String TOKEN_NAME_UPD   = "更新処理";
  /** トークン名称：削除処理 */
  public static final String TOKEN_NAME_DEL   = "削除処理";
  /** トークン名称：確定処理 */
  public static final String TOKEN_NAME_FIX   = "確定処理";
  /** トークン名称：受領処理 */
  public static final String TOKEN_NAME_RCV   = "受領処理";
  /** トークン名称：手動指示確定処理 */
  public static final String TOKEN_NAME_MANUAL_FIX  = "手動指示確定処理";
  /** トークン名称：金額確定処理*/
  public static final String TOKEN_NAME_AMOUNT_FIX  = "金額確定処理";
  /** トークン名称：価格設定処理 */
  public static final String TOKEN_NAME_PRICE_SET   = "価格設定処理";
  /** トークン名称：支給取消処理 */
  public static final String TOKEN_NAME_PROV_CANCEL = "支給取消処理";
  /** トークン名称：出荷実績計上済 */
  public static final String TOKEN_NAME_PROV_STATUS_SJK = "出荷実績計上済";
  /** トークン名称：仕入実績作成処理 */
  public static final String TOKEN_NAME_STOCK_RESULT_MAKE = "仕入実績作成処理";
  /** トークン名称：配車処理 */
  public static final String TOKEN_NAME_CAREERS = "配車処理";
  /** トークン名称：配車解除処理 */
  public static final String TOKEN_NAME_CAN_CAREERS = "配車解除処理";
  /** トークン名称：引当処理 */
  public static final String TOKEN_NAME_RESERVE = "引当処理";
  /** トークン名称：全数出庫処理 */
  public static final String TOKEN_NAME_ALL_SHIPPED = "全数出庫処理";
  /** トークン名称：全数入庫処理 */
  public static final String TOKEN_NAME_ALL_SHIP_TO = "全数入庫処理";
  /** トークン名称：全数入庫処理 */
  public static final String TOKEN_NAME_CALC_ERR    = "合計重量/容積算出処理";
  /** トークン名称：全数入庫処理 */
  public static final String TOKEN_NAME_CALC_LOAD_ERR = "積載効率算出処理";
  /** トークン名称：依頼No */
  public static final String TOKEN_NAME_REQUEST_NO = "依頼No";
  /** トークン名称：出庫処理 */
  public static final String TOKEN_CONC_NAME = "コンカレント名称";
// 2008-10-23 H.Itou Add START
  /** トークン名称：伊藤園在庫管理倉庫 */
  public static final String TOKEN_CUSTOMER_STOCK_WHSE_ITOEN = "伊藤園在庫管理倉庫";
  /** トークン名称：相手先在庫管理倉庫 */
  public static final String TOKEN_CUSTOMER_STOCK_WHSE_AITE = "相手先在庫管理倉庫";
// 2008-10-23 H.Itou Add END
// 2011-06-01 v1.9 K.Kubo Add Start 本番#1786
  /** トークン名称：仕入実績情報登録 */
  public static final String TOKEN_NAME_STOCK_RESULT_MANEGEMENT = "仕入実績情報登録";
  /** トークン名称：仕入実績情報チェック */
  public static final String TOKEN_NAME_CHK_STOCK_RESULT_MANE = "仕入実績情報チェック";
// 2011-06-01 v1.9 K.Kubo Add End   本番#1786
  /** アプリケーション短縮名：XXPO⇒使用不可 */
  public static final String APPL_XXPO = "XXPO";
  /** 試験有無区分：1 有 */
  public static final String QT_TYPE_ON  = "1";
  /** 試験有無区分：0 無 */
  public static final String QT_TYPE_OFF = "0";
  /** 処理タイプ：0 生産実績なし */
  public static final String PRODUCT_RESULT_TYPE_M = "0";
  /** 処理タイプ：1 相手先在庫管理 */
  public static final String PRODUCT_RESULT_TYPE_I = "1";
  /** 処理タイプ：2 即時仕入 */
  public static final String PRODUCT_RESULT_TYPE_P = "2";
  /** 原価管理区分：1 標準原価 */
  public static final String COST_MANAGE_CODE_N = "1";
  /** 原価管理区分：0 実際原価 */
  public static final String COST_MANAGE_CODE_R = "0";
  /** 処理フラグ：1 登録 */
  public static final String PROCESS_FLAG_I = "1";
  /** 処理フラグ：2 更新 */
  public static final String PROCESS_FLAG_U = "2";
  /** 従業員区分：1 内部 */
  public static final String PEOPLE_CODE_I  = "1";
  /** 従業員区分：2 外部 */
  public static final String PEOPLE_CODE_O  = "2";
  /** 区分：2 発注 */
  public static final String DIVISION_PO    = "2";
  /** 区分：4 外注出来高 */
  public static final String DIVISION_SPL   = "4";
  /** ステータス：15 発注作成中 */
  public static final String STATUS_ORDERING_MAKING = "15";
  /** ステータス：20 発注作成済 */
  public static final String STATUS_FINISH_ORDERING_MAKING = "20";
  /** ステータス：25 受入あり */
  public static final String STATUS_REPUTATION_CASE        = "25";
  /** ステータス：30 数量確定済 */
  public static final String STATUS_FINISH_DECISION_AMOUNT = "30";
  /** ステータス：35 金額確定済 */
  public static final String STATUS_FINISH_DECISION_MONEY  = "35";
  /** ステータス：99 取消 */
  public static final String STATUS_CANCEL = "99";
  /** 金額確定フラグ：Y 承諾済み */
  public static final String MONEY_DECISION_FLAG_Y = "Y";
  /** 金額確定フラグ：N 未承諾 */
  public static final String MONEY_DECISION_FLAG_N = "N";
  /** ロット：0 ロット対象外 */
  public static final String LOT_CTL_0 = "0";
  /** ロット：1 ロット対象 */
  public static final String LOT_CTL_1 = "1";
  /** 承諾要求区分：1 承諾要 */
  public static final String APPROVED_REQ_TYPE_1 = "1";
  /** 承諾要求区分：2 承諾不要 */
  public static final String APPROVED_REQ_TYPE_2 = "2";
  /** 直送区分：1 通常 */
  public static final String DSHIP_USUALLY   = "1";
  /** 直送区分：2 出荷 */
  public static final String DSHIP_SHIPMENT  = "2";
  /** 直送区分：3 支給 */
  public static final String DSHIP_PROVISION = "3";
  /** 承諾区分：1 承諾済 */
  public static final String APPROVED_TYPE_1 = "1";
  /** 承諾区分：2 未承諾 */
  public static final String APPROVED_TYPE_2 = "2";
  /** 起動条件：1 メニューから起動 */
  public static final String START_CONDITION_1 = "1";
  /** 起動条件：2 検索画面から遷移 */
  public static final String START_CONDITION_2 = "2";
  /** 有償金額確定区分：1 確定 */
  public static final String FIX_CLASS_ON  = "1";
  /** 有償金額確定区分：2 未確定 */
  public static final String FIX_CLASS_OFF = "2";
  /** 発注区分：1 新規 */
  public static final String PO_TYPE_1 = "1";
  /** 発注区分：2 検査ロット */
  public static final String PO_TYPE_2 = "2";
  /** 発注区分：3 相手先在庫 */
  public static final String PO_TYPE_3 = "3";
  /** 新規修正フラグ：0 修正なし */
  public static final String NEW_MODIFY_FLG_OFF = "0";
  /** 支給指示受領区分：1 受領済  */
  public static final String RCV_CLASS_ON  = "1";
  /** 支給指示受領区分：2 未受領  */
  public static final String RCV_CLASS_OFF = "2";
// 2008-10-23 H.Itou Add Start
  /** 相手先在庫管理対象：0 伊藤園在庫管理対象  */
  public static final String CUSTOMER_STOCK_WHSE_ITOEN = "0";
  /** 相手先在庫管理対象：1 相手先在庫管理対象  */
  public static final String CUSTOMER_STOCK_WHSE_AITE = "1";
// 2008-10-23 H.Itou Add End
  /** URL：発注受入:検索画面 */
  public static final String URL_XXPO310001JS = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo310001j/webui/XxpoOrderReceiptPG";
  /** URL：発注受入:詳細画面 */
  public static final String URL_XXPO310001JD = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo310001j/webui/XxpoOrderReceiptDetailsPG";
  /** URL：発注受入:入力画面 */
  public static final String URL_XXPO310001JM = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo310001j/webui/XxpoOrderReceiptMakePG";
  /** URL：仕入先出荷実績:検索画面 */
  public static final String URL_XXPO320001JS = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo320001j/webui/XxpoSupplierResultsPG";
  /** URL：仕入先出荷実績:登録画面 */
  public static final String URL_XXPO320001JM = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo320001j/webui/XxpoSupplierResultsMakePG";
  /** URL：外注出来高実績:検索画面 */
  public static final String URL_XXPO340001JS = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo340001j/webui/XxpoVendorSupplyPG";
  /** URL：外注出来高実績:登録画面 */
  public static final String URL_XXPO340001JM = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo340001j/webui/XxpoVendorSupplyMakePG";
  /** URL：発注実績:検索画面 */
  public static final String URL_XXPO350001JS = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo350001j/webui/XxpoPoConfirmPG";
  /** URL：発注・受入照会画面 */
  public static final String URL_XXPO350001JI = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo350001j/webui/XxpoPoInquiryPG";
  /** URL：検査ロット検索画面 */
  public static final String URL_XXPO370001J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchPG";
  /** URL：検査ロット登録画面 */
  public static final String URL_XXPO370002J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG";
  /** URL：支給依頼要約画面 */
  public static final String URL_XXPO440001J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo440001j/webui/XxpoProvisionRequestPG";
  /** URL：出庫実績要約画面 */
  public static final String URL_XXPO441001J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo441001j/webui/XxpoShippedResultPG";
  /** URL：出庫実績入力ヘッダ画面 */
  public static final String URL_XXPO441001JH = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo441001j/webui/XxpoShippedMakeHeaderPG";
  /** URL：出庫実績入力明細画面 */
  public static final String URL_XXPO441001JL = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo441001j/webui/XxpoShippedMakeLinePG";
  /** URL：入庫実績要約画面 */
  public static final String URL_XXPO442001J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo442001j/webui/XxpoShipToResultPG";
  /** URL：入庫実績入力ヘッダ画面 */
  public static final String URL_XXPO442001JH = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo442001j/webui/XxpoShipToHeaderPG";
  /** URL：入庫実績入力明細画面 */
  public static final String URL_XXPO442001JL = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo442001j/webui/XxpoShipToLinePG";
  /** URL：支給指示作成ヘッダ画面 */
  public static final String URL_XXPO440001JH = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo440001j/webui/XxpoProvisionInstMakeHeaderPG";
  /** URL：支給指示作成明細画面 */
  public static final String URL_XXPO440001JL = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo440001j/webui/XxpoProvisionInstMakeLinePG";
  /** URL：支給返品要約画面 */
  public static final String URL_XXPO443001J  = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo443001j/webui/XxpoProvisionRtnSummaryPG";
  /** URL：支給返品作成ヘッダ画面 */
  public static final String URL_XXPO443001JH = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo443001j/webui/XxpoProvisionRtnMakeHeaderPG";
  /** URL：支給返品作成明細画面 */
  public static final String URL_XXPO443001JL = "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo443001j/webui/XxpoProvisionRtnMakeLinePG";
  /** URLパラメータID：検索用実績ID */
  public static final String URL_PARAM_SEARCH_TXNS_ID    = "pSearchTxnsId";
  /** URLパラメータID：更新フラグ */
  public static final String URL_PARAM_UPDATE_FLAG       = "pUpdateFlag";
  /** URLパラメータID：検索用ヘッダID */
  public static final String URL_PARAM_SEARCH_HEADER_ID  = "pSearchHeaderId";
  /** URLパラメータID：検索用直送区分CODE */
  public static final String URL_PARAM_SEARCH_DSHIP_CODE = "pSearchDShipCode";  
  /** URLパラメータID：検索用明細番号 */
  public static final String URL_PARAM_CHANGED_LINE_NUMBER = "pChangedLineNum";
  /** URLパラメータID：検索用発注番号 */
  public static final String URL_PARAM_HEADER_NUMBER     = "pHeaderNum";
  /** URLパラメータID：起動条件 */
  public static final String URL_PARAM_START_CONDITION   = "pStartCondition";
  /** URLパラメータID：有償支給:起動タイプ */
  public static final String URL_PARAM_EXE_TYPE          = "pExeType";
  /** URLパラメータID：有償支給:依頼No */
  public static final String URL_PARAM_REQ_NO            = "pReqNo";
  /** URLパラメータID：有償支給:元依頼No */
  public static final String URL_PARAM_BASE_REQ_NO       = "pBaseReqNo";
  /** URLパラメータID：有償支給:前画面URL */
  public static final String URL_PARAM_PREV_URL          = "pPrevUrl";
  /** URLパラメータID：有償支給:完了メッセージ */
  public static final String URL_PARAM_MAIN_MESSAGE      = "pMainMessage";
  /** URLパラメータID：有償支給:支給取消完了メッセージ */
  public static final String URL_PARAM_CAN_MESSAGE       = "pCancelMessage";
  /** テーブル日本語名：xxpo_vendor_supply_txns */
  public static final String TAB_XXPO_VENDOR_SUPPLY_TXNS    = "外注出来高実績(アドオン)";
  /** テーブル日本語名：xxwip_qt_inspection */
  public static final String TAB_XXWIP_QT_INSPECTION        = "品質検査依頼情報(アドオン)";
  /** テーブル日本語名：po_distributions_interface */
  public static final String TAB_PO_DISTRIBUTIONS_INTERFACE = "搬送明細オープンインタフェース";
  /** テーブル日本語名：po_lines_interface */
  public static final String TAB_PO_LINES_INTERFACE         = "発注明細オープンインタフェース";
  /** テーブル日本語名：po_headers_interface */
  public static final String TAB_PO_HEADERS_INTERFACE       = "発注ヘッダオープンインタフェース";
  /** テーブル日本語名：xxpo_rcv_and_rtn_txns */
  public static final String TAB_XXPO_RCV_AND_RTN_TXNS      = "受入返品実績(アドオン)";
  /** テーブル日本語名：ic_lots_mst */
  public static final String TAB_IC_LOTS_MST = "OPMロットマスタ";
  /** テーブル日本語名：ic_tran_cmp */
  public static final String TAB_IC_TRAN_CMP = "在庫取引";
  /** テーブル日本語名：gmf_lot_cost_adjustments */
  public static final String TAB_GMF_LOT_COST_ADJUSTMENTS = "ロット原価";
  /** テーブル日本語名：xxpo_headers_all */
  public static final String TAB_XXPO_HEADERS_ALL  = "発注ヘッダ(アドオン)";
  /** テーブル日本語名：xxpo_headers_all */
  public static final String TAB_PO_HEADERS_ALL    = "発注ヘッダ";
  /** テーブル日本語名：xxpo_headers_all */
  public static final String TAB_PO_LINES_ALL      = "発注明細";
  /** テーブル日本語名：rcv_headers_interface */
  public static final String TAB_RCV_HEADERS_INTERFACE      = "受入ヘッダオープンインタフェース";
  /** テーブル日本語名：rcv_transactions_interface */
  public static final String TAB_RCV_TRANSACTIONS_INTERFACE = "受入トランザクションオープンインタフェース";
  /** テーブル日本語名：mtl_transaction_lots_interface */
  public static final String TAB_MTL_TRANSACTION_LOTS_INTERFACE = "品目ロットトランザクションオープンインタフェース";
  /** テーブル日本語名：rcv_lots_interface */
  public static final String TAB_RCV_LOTS_INTERFACE = "受入ロットトランザクションオープンインタフェース";
  /** 列名：qt_inspect_req_no */
  public static final String COL_QT_INSPECT_REQ_NO  = "検査依頼No";
  /** 列名：manufactured_date */
  public static final String COL_MANUFACTURED_DATE  = "生産日";
  /** 列名：vendor_code */
  public static final String COL_VENDOR_CODE  = "取引先";
  /** 列名：factory_code */
  public static final String COL_FACTORY_CODE = "工場";
  /** 列名：item_code */
  public static final String COL_ITEM_CODE    = "品目";
  /** 列名：lot_number */
  public static final String COL_LOT_NUMBER   = "ロットNo";
  /** コロン */
  public static final String COLON = ":";
  /** カンマ */
  public static final String COMMA = ",";
  /** スペース */
  public static final String SPACE = " ";
  /** 起動タイプ：11「支給指示：伊藤園用」 */
  public static final String EXE_TYPE_11  = "11";
  /** 起動タイプ：12「支給指示：パッカー・外注工場用」 */
  public static final String EXE_TYPE_12  = "12";
  /** 起動タイプ：13「支給指示：東洋埠頭用」 */
  public static final String EXE_TYPE_13  = "13";
  /** 起動タイプ：15「支給指示：資材メーカー用」 */
  public static final String EXE_TYPE_15  = "15";
  /** 起動タイプ：21「出庫実績：伊藤園用」 */
  public static final String EXE_TYPE_21  = "21";
  /** 起動タイプ：23「出庫実績：東洋埠頭用」 */
  public static final String EXE_TYPE_23  = "23";
  /** 起動タイプ：24「出庫実績：外部倉庫用」 */
  public static final String EXE_TYPE_24  = "24";
  /** 起動タイプ：25「出庫実績：資材メーカー用」 */
  public static final String EXE_TYPE_25  = "25";
  /** 起動タイプ：31「入庫実績：伊藤園用」 */
  public static final String EXE_TYPE_31  = "31";
  /** 起動タイプ：32「入庫実績：パッカー・外注工場用」 */
  public static final String EXE_TYPE_32  = "32";
  /** 起動タイプ：51「支給返品：伊藤園用」 */
  public static final String EXE_TYPE_51  = "51";
  /** 支給依頼ステータス：「05：入力中」 */
  public static final String PROV_STATUS_NRT  = "05";
  /** 支給依頼ステータス：「06：入力完了」 */
  public static final String PROV_STATUS_NRK  = "06";
  /** 支給依頼ステータス：「07：受領済」 */
  public static final String PROV_STATUS_ZRZ  = "07";
  /** 支給依頼ステータス：「08：出荷実績計上済」 */
  public static final String PROV_STATUS_SJK  = "08";
  /** 支給依頼ステータス：「99：取消」 */
  public static final String PROV_STATUS_CAN  = "99";
  /** 通知ステータス：「10：未通知」 */
  public static final String NOTIF_STATUS_MTT = "10";
  /** 通知ステータス：「20：再通知要」 */
  public static final String NOTIF_STATUS_STY = "20";
  /** 通知ステータス：「40：確定通知済」 */
  public static final String NOTIF_STATUS_KTZ = "40";
  /** 事由コード(プロファイル)：「相手先在庫」 */
  public static final String CTPTY_INV_SHIP_RSN = "XXPO_CTPTY_INV_SHIP_RSN";
  /** プロファイル：「代表価格表ID」 */
  public static final String REP_PRICE_LIST_ID = "XXPO_PRICE_LIST_ID";
  /** レコードタイプ : 「20 : 出庫」　 */
  public static final String REC_TYPE_20 = "20";
  /** レコードタイプ : 「30 : 入庫」　 */
  public static final String REC_TYPE_30 = "30";
  /** 受領タイプ : 「5 : 一部実績有」　 */
  public static final String RCV_TYPE_5 = "5";
  /** 受領タイプ : 「4 : 配車済・引当有」　 */
  public static final String RCV_TYPE_4 = "4";
  /** 受領タイプ : 「3 : 配車済・未引当」　 */
  public static final String RCV_TYPE_3 = "3";
  /** 受領タイプ : 「2 : 引当有」　 */
  public static final String RCV_TYPE_2 = "2";
  /** 受領タイプ : 「1 : 発注済」　 */
  public static final String RCV_TYPE_1 = "1";
  /** 受領タイプ : 「0 : 未発注」　 */
  public static final String RCV_TYPE_0 = "0";
  /** 重量容積区分 : 「1 : 重量」　 */
  public static final String WGHT_CAPA_CLASS_WEIGHT   = "1";
  /** 重量容積区分 : 「2 : 容積」　 */
  public static final String WGHT_CAPA_CLASS_CAPACITY = "2";
  /** シーケンス : 「受注ヘッダアドオンID用」　 */
  public static final String XXWSH_ORDER_HEADERS_ALL_S1 = "xxwsh_order_headers_all_s1";
  /** シーケンス : 「受注明細アドオンID用」　 */
  public static final String XXWSH_ORDER_LINES_ALL_S1 = "xxwsh_order_lines_all_s1";
  /** 品目区分：1 原料 */
  public static final String ITEM_CLASS_MTL    = "1";
  /** 品目区分：2 資材 */
  public static final String ITEM_CLASS_SHZ    = "2";
  /** 品目区分：4 半製品 */
  public static final String ITEM_CLASS_HALF   = "4";
  /** 品目区分：5 製品 */
  public static final String ITEM_CLASS_PROD   = "5";
  /** 商品区分：1 リーフ */
  public static final String PROD_CLASS_LEAF   = "1";
  /** 商品区分：2 ドリンク */
  public static final String PROD_CLASS_DRINK  = "2";
}
