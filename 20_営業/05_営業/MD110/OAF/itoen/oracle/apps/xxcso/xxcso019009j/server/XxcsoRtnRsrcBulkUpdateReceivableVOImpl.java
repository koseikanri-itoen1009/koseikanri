/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateReceivableVOImpl
* 概要説明   : 入金拠点ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2015-09-08 1.0  SCSK桐生和幸  [E_本稼動_13307]新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 入金拠点のビュークラスです。
 * @author  SCSK桐生和幸
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateReceivableVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateReceivableVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param AccountNumber       顧客コード
   * @param baseCode            拠点コード
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, AccountNumber);
    setWhereClauseParam(1, baseCode);

    executeQuery();
  }
}