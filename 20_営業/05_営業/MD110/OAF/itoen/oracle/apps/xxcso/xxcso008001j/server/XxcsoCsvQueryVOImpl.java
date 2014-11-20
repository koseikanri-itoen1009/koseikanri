/*============================================================================
* ファイル名 : XxcsoCsvQueryVOImpl
* 概要説明   : 週次活動状況照会／CSV出力Query格納用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS柳平直人  新規作成
* 2009-06-23 1.2  SCS柳平直人  [障害0000102]CSV出力性能改善対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2009-06-23 [障害0000102] Add Start
import oracle.jbo.domain.Number;
// 2009-06-23 [障害0000102] Add End

/*******************************************************************************
 * CSV出力Query格納用ビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCsvQueryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCsvQueryVOImpl()
  {
  }

// 2009-06-23 [障害0000102] Add Start
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
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);

    // SQL実行
    executeQuery();
  }
// 2009-06-23 [障害0000102] Add End

}