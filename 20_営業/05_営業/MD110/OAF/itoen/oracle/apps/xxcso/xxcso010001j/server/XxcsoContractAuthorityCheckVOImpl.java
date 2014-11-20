/*============================================================================
* ファイル名 : XxcsoContractAuthorityCheckVOImpl
* 概要説明   : 権限チェックビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-20 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 権限チェックするためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractAuthorityCheckVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractAuthorityCheckVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param spDecisionHeaderId     SP専決ヘッダID
   *****************************************************************************
   */
  public void getAuthority(
    Number spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}