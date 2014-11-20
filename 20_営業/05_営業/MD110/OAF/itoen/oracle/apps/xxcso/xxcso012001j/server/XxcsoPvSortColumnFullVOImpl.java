/*============================================================================
* ファイル名 : XxcsoPvSortColumnFullVOImpl
* 概要説明   : パーソナライズビュー作成画面／汎用検索ソート定義取得ビューオブジェクトクラス
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
 * 汎用検索ソート定義取得ビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSortColumnFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvSortColumnFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId        ビューID
   *****************************************************************************
   */
  public void initQuery(
    String pVUseMode
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, pVUseMode);

  }

}