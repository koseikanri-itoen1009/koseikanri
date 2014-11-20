/*============================================================================
* ファイル名 : XxcsoTaskSummaryVOImpl
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
import oracle.jbo.domain.Number;

/*******************************************************************************
 * スケジュールリージョンを検索するためのビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param appDate     指定日付
   * @param resourceId  リソースID
   *****************************************************************************
   */
  public void initQuery(
    String appDate
    ,Number resourceId
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);

    // SQL実行
    executeQuery();
  }
}