/*============================================================================
* ファイル名 : XxccpLookUpValueVOImpl.java
* 概要説明   : 参照タイプビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp008A01j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 参照タイプビューオブジェクトクラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpLookUpValueVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpLookUpValueVOImpl()
  {
  }

  /**
   * 参照タイプを取得する。
   * @param lookuptype ルックアップタイプ
   * @param conType コード
   */
  public void getLookUpValue(String lookuptype, String conType)
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, lookuptype);
    setWhereClauseParam(1, conType);
    executeQuery();
  }
}