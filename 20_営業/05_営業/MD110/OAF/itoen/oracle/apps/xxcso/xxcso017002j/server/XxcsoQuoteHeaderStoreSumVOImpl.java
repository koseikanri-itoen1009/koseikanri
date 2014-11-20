/*============================================================================
* ファイル名 : XxcsoQuoteHeaderStoreSumVOImpl
* 概要説明   : 見積ヘッダ再読込み用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 見積ヘッダ情報を再読込みするためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteHeaderStoreSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeaderStoreSumVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param quoteHeaderId 見積ヘッダーID
   *****************************************************************************
   */
  public void initQuery(
    String quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, quoteHeaderId);

    executeQuery();

  }
}