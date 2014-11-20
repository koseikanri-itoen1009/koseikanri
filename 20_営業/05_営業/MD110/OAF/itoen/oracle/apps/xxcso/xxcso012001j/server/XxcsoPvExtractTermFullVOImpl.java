/*============================================================================
* ファイル名 : XxcsoPvExtractTermFullVOImpl
* 概要説明   : パーソナライズビュー作成画面／汎用検索抽出条件定義取得ビューオブジェクト
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
 * 汎用検索抽出条件定義取得ビュー行オブジェクトビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractTermFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractTermFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param pvUseMode     汎用検索使用モード
   *****************************************************************************
   */
  public void initQuery(
    String pvUseMode
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, pvUseMode);
    setWhereClauseParam(idx++, pvUseMode);

  }

}