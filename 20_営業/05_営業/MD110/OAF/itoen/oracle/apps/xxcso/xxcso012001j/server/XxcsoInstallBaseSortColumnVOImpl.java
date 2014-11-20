/*============================================================================
* ファイル名 : XxcsoInstallBaseSortColumnVOImpl
* 概要説明   : 物件情報汎用検索画面／ソート条件取得ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ソート条件を取得するためのビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseSortColumnVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseSortColumnVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索表示モード
   *****************************************************************************
   */
  public void initQuery(
    String  viewId
   ,String pvDisplayMode
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, pvDisplayMode);
    setWhereClauseParam(idx++, viewId);

    // SQL実行
    executeQuery();
  }

}