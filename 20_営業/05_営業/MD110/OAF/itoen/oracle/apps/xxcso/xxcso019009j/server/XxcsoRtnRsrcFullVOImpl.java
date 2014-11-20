/*============================================================================
* ファイル名 : XxcsoRtnRsrcFullVOImpl
* 概要説明   : 一括更新リージョンビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基  新規作成
* 2009-06-24 1.1  SCS柳平直人  [障害0000032]検索性能改善対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 一括更新リージョンのビュークラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param resourceNo          リソース番号
   * @param routeNo             ルートNo
   * @param baseCode            拠点コード
   *****************************************************************************
   */
  public void initQuery(
    String resourceNo
   ,String routeNo
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, resourceNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
// 2009-06-24 [障害0000032] Mod Start
//    setWhereClauseParam(index++, resourceNo);
//    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, resourceNo);
// 2009-06-24 [障害0000032] Mod End
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);

    executeQuery();
  }
}