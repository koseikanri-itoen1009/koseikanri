/*============================================================================
* ファイル名 : XxcsoEmpNameSummaryVOImpl
* 概要説明   : 週次活動状況照会／検索用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * スケジュールリージョン（担当者名）を検索するためのビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpNameSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpNameSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param empName    担当者名
   *****************************************************************************
   */
  public void initQuery(
    String empName
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, empName);

    // SQL実行
    executeQuery();
  }

}