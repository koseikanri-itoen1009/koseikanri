/*============================================================================
* ファイル名 : XxinvLookUpValueVOImpl.java
* 概要説明   : 参照タイプビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-23 1.0  高梨雅史      新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv990001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 参照タイプビューオブジェクトクラスです。
 * @author  ORACLE 高梨雅史
 * @version 1.0
 ***************************************************************************
 */
public class XxinvLookUpValueVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvLookUpValueVOImpl()
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