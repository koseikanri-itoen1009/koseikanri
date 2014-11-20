/*============================================================================
* ファイル名 : XxccpUserRespCheckVOImpl
* 概要説明   : ユーザー・職責チェックビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ログインユーザーの職責をチェックするためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxccpUserRespCheckVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpUserRespCheckVOImpl()
  {
  }


  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param userName ログインユーザー名
   *****************************************************************************
   */
  public void initQuery(
    String userName
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, userName);
    setWhereClauseParam(1, userName);

    executeQuery();
  }
}