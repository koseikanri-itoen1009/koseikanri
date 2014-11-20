/*============================================================================
* ファイル名 : XxcsoContractConstants
* 概要説明   : 契約書検索固定値クラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-20 1.0  SCS及川領    新規作成
* 2009-05-26 1.1  SCS柳平直人  [ST障害T1_1165]明細チェック障害対応
* 2010-02-09 1.2  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.util;

/*******************************************************************************
 * 契約書検索の固定値クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractConstants 
{
  /*****************************************************************************
   * エラーメッセージ名
   *****************************************************************************
   */
  public static final String MSG_SP_DECISION_NUMBER    = "参照ＳＰ専決書番号";
  public static final String MSG_SP_DECISION           = "SP専決書";
  public static final String MSG_CONTRACT              = "契約書";
  public static final String MSG_CONTRACT_CREATE       = "契約書作成";
  public static final String MSG_COPY_CREATE           = "コピー作成";
  public static final String MSG_PDF_CREATE            = "ＰＤＦ";
  public static final String MSG_DETAILS               = "詳細";
// 2009-05-26 [ST障害T1_1165] Add Start
  public static final String MSG_CONTRACT_NUMBER       = "契約書番号";
// 2009-05-26 [ST障害T1_1165] Add End

  /*****************************************************************************
   * 画面共通区分
   *****************************************************************************
   */
  public static final String CONSTANT_COM_KBN0  = "0";
  public static final String CONSTANT_COM_KBN1  = "1";
  public static final String CONSTANT_COM_KBN2  = "2";
  public static final String CONSTANT_COM_KBN3  = "3";

  /*****************************************************************************
   * プロファイル値
   *****************************************************************************
   */
  public static final String VIEW_SIZE        = "XXCSO1_VIEW_SIZE_010_A01_01";

  /*****************************************************************************
   * リージョン名
   *****************************************************************************
   */
  public static final String REGION_NAME      = "ResultsAdvTblRN";

  /*****************************************************************************
   * 契約検索用トークン値
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_PDF_OUT       = "契約書PDF出力";
  public static final String TOKEN_VALUE_START         = "起動";
// 2010-02-09 [E_本稼動_01538] Mod Start
  public static final String TOKEN_VALUE_CANCEL_CONTRACT = "取消済契約書チェック";
  public static final String TOKEN_VALUE_LATEST_CONTRACT = "最新契約書チェック";
  public static final String 
                TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK = "マスタ連携待ちチェック";
// 2010-02-09 [E_本稼動_01538] Mod End

}