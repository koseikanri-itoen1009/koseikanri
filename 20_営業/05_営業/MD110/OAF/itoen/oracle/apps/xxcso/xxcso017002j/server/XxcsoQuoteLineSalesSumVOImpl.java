/*============================================================================
* ファイル名 : XxcsoQuoteLinesStoreFullVOImpl
* 概要説明   : 見積明細販売情報参照用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 見積明細販売情報を参照するためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteLineSalesSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteLineSalesSumVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param quoteHeaderId 見積ヘッダーID
   *****************************************************************************
   */
  public void initQuery(
    Number quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, quoteHeaderId);

    executeQuery();
  }
}