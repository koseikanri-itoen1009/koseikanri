/*============================================================================
* ファイル名 : XxpoProvisionInstMakeHeaderVOImpl
* 概要説明   : 支給指示作成コピーヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-06-09 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 支給指示作成コピーヘッダビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvCopyHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvCopyHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param baseReqNo - 元依頼No
   ****************************************************************************/
  public void initQuery(String baseReqNo)
  {
    // 初期化
    setWhereClauseParams(null);
    setWhereClauseParam(0, baseReqNo);
    // 検索実行
    executeQuery();
  }
}