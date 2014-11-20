/*============================================================================
* ファイル名 : XxcsoDispayColumnInitVOImpl
* 概要説明   : パーソナライズビュー作成画面／表示列(新規作成)ビューオブジェクト
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
 * 表示列(新規作成)を検索するためのビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDispayColumnInitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDispayColumnInitVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param pvDispMode     汎用検索表示モード
   *****************************************************************************
   */
  public void initQuery(
    String pvDispMode
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);

    // SQL実行
    executeQuery();
  }

}