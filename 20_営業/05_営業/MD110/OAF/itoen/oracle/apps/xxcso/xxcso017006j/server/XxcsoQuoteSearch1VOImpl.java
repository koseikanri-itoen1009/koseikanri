/*============================================================================
* ファイル名 : XxcsoQuoteSearch1VOImpl
* 概要説明   : 見積検索ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS張吉    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 見積検索の版が入力された場合のビュークラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearch1VOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearch1VOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param quoteType         見積種別
   * @param quoteNumber       見積番号
   * @param quoteResionNumber 版
   *****************************************************************************
   */
  public void initQuery(
    String quoteType,
    String quoteNumber,
    String quoteResionNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, quoteType);
    setWhereClauseParam(index++, quoteNumber);
    setWhereClauseParam(index++, quoteResionNumber);

    executeQuery();
  }
}