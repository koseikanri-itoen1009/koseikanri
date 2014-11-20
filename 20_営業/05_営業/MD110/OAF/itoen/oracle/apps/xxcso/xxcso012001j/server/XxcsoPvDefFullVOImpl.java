/*============================================================================
* ファイル名 : XxcsoPvDefFullVOImpl
* 概要説明   : パーソナライズビュー作成画面／汎用検索テーブル取得ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 一般プロパティを検索するためのビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId     ビューID
   * @param isCopy     true:新規作成、複製 false:更新
   *****************************************************************************
   */
  public void initQuery(
    String viewId
   ,boolean isCopy
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    if ( isCopy )
    {
      setWhereClause("1=2");
    }
    int idx = 0;
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL実行
    executeQuery();
  }
}