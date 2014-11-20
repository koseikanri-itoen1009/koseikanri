/*============================================================================
* ファイル名 : XxpoProvisionRtnMakeHeaderVOImpl
* 概要説明   : 支給返品作成ヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  熊本 和郎    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 支給返品作成ヘッダビューオブジェクトクラスです。
 * @author  ORACLE 熊本 和郎
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param reqNo - 依頼No
   ****************************************************************************/
  public void initQuery(String reqNo) 
  {
    // 検索条件付加
    setWhereClauseParam(0, reqNo);

    // 検索実行
    executeQuery();
  }
}