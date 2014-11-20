/*============================================================================
* ファイル名 : XxpoShipToHeaderVOImpl
* 概要説明   : 入庫実績入力ヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  新藤義勝     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
 /***************************************************************************
  * 入庫実績入力ヘッダビューオブジェクトクラスです。
  * @author  ORACLE 新藤 義勝
  * @version 1.0
  ***************************************************************************
  */
 public class XxpoShipToHeaderVOImpl extends OAViewObjectImpl 
 {
   /**
    * 
    * This is the default constructor (do not remove)
    */
  public XxpoShipToHeaderVOImpl()
  { 
    
  } // コンストラクタ
   
 /*****************************************************************************
  * VOの初期化を行います。
  * @param reqNo - 依頼No
  *****************************************************************************
  */
  public void initQuery(String reqNo)
  {
    // 初期化
    setWhereClauseParams(null);
    setWhereClauseParam(0, reqNo);
    // 検索実行
    executeQuery();
  }
}