/*============================================================================
* ファイル名 : XxcsoReferenceQuoteVOImpl
* 概要説明   : 帳合問屋検索用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/*******************************************************************************
 * 帳合問屋で対象明細を使用しているか検索するためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuoteVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuoteVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param QuoteHeaderId       見積ヘッダID
   *****************************************************************************
   */
  public void initQuery(
    Number quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, quoteHeaderId);

    executeQuery();
  }


}