/*============================================================================
* ファイル名 : XxcsoInstallBasePvSumVOImpl
* 概要説明   : 物件情報汎用検索画面／物件情報検索ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-24 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 物件情報を検索するためのビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvSumVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param whereStmt        検索条件
   * @param orderBy          ソート条件
   *****************************************************************************
   */
  public void initQuery(
    String whereStmt
   ,String orderBy
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClause(whereStmt);
    setOrderByClause(orderBy);

    executeQuery();
  }
}