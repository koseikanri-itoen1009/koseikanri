/*============================================================================
* ファイル名 : XxpoPoInquiryVOImpl
* 概要説明   : 発注・受入照会画面ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 発注・受入照会画面ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquiryVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchHeaderId         - 検索パラメータ
   ****************************************************************************/
  public void initQuery(String searchHeaderId)
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchHeaderId);
  
    // SELECT文実行
    executeQuery();
  }
}