/*============================================================================
* ファイル名 : XxpoProvisionInstMakeHeaderVOImpl
* 概要説明   : 支給指示作成ヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-10 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 支給指示作成ヘッダビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionInstMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionInstMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param reqNo - 依頼No
   ****************************************************************************/
  public void initQuery(String reqNo)
  {
    // 初期化
    setWhereClauseParams(null);
    setWhereClauseParam(0, reqNo);
    // 検索実行
    executeQuery();
  }
}