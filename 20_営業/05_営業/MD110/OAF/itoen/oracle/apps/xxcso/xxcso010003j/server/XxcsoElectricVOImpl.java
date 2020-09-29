/*============================================================================
* ファイル名 : XxcsoElectricVOImpl
* 概要説明   : 電気代ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- -------------- --------------------------------------------
* 2020-08-21 1.0  SCSK佐々木大和   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 電気代ビューオブジェクトクラス
 * @author  SCSK佐々木大和
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoElectricVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoElectricVOImpl()
  {
  }
  
  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param spDecisionHeaderId SP専決ヘッダーID
   *****************************************************************************
   */
  public void initQuery(
    String spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}