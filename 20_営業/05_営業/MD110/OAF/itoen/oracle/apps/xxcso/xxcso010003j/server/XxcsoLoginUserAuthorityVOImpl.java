/*============================================================================
* ファイル名 : XxcsoLoginUserAuthorityVOImpl
* 概要説明   : ログインユーザー権限取得ビューオブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ログインユーザー権限取得ビューオブジェクトクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLoginUserAuthorityVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLoginUserAuthorityVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param spDecisionHeaderId SP専決ヘッダーID
   *****************************************************************************
   */
  public void initQuery(
    String spDecisionCustomerId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionCustomerId);

    executeQuery();
  }

}